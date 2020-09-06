#include <stdbool.h>

void outb(unsigned short port, char val) {
  asm volatile (
    "outb %[val], %[port]\n\t"
    :
    : [val] "al" (val), [port] "dx" (port)
  );
}

void printstring(char const *val) {
  while(*val)
    outb(0xE9, *val++);
}

void shutdown(void) {
  outb(0x64, 0xFE);
}

void print_hex_impl(unsigned long long num, int nibbles) { for(int i = nibbles - 1; i >= 0; -- i) outb(0xE9, "0123456789ABCDEF"[(num >> (i * 4))&0xF]); }
#define print_hex(num) print_hex_impl((unsigned long long)(num), sizeof((num)) * 2)

struct Bootelf_memmap_entry {
  unsigned long long base;
  unsigned long long size;
  unsigned type;
  unsigned acpi3type;
};

struct Bootelf_data {
  unsigned long long magic;
  unsigned long long numEntries;
  struct Bootelf_memmap_entry *entries;
};

#define print_value(str, val) \
  do {\
    printstring(str);\
    printstring("0x");\
    print_hex(val);\
    printstring("\n");\
  } while(0)

int _start(struct Bootelf_data *ptr) {
  printstring("Dumping data passed from bootelf!\n");

  print_value("Bootelf ptr: ", ptr);
  print_value("Bootelf magic: ", ptr->magic);
  print_value("Bootelf memmap size: ", ptr->numEntries);
  print_value("Bootelf memmap ptr: ", ptr->entries);

  for(unsigned i = 0; i < ptr->numEntries; ++ i) {
    print_value("Memmap entry ", i);
    print_value(" base:  ", ptr->entries[i].base);
    print_value(" size:  ", ptr->entries[i].size);
    print_value(" type:  ", ptr->entries[i].type);
    print_value(" acpi3: ", ptr->entries[i].acpi3type);
  }

  shutdown();
  while(1);
}
