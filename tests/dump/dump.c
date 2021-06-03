#include <stdbool.h>

typedef unsigned int u32;
typedef unsigned long long u64;

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

void print_hex_impl(u64 num, int nibbles) { for(int i = nibbles - 1; i >= 0; -- i) outb(0xE9, "0123456789ABCDEF"[(num >> (i * 4))&0xF]); }
#define print_hex(num) print_hex_impl((u64)(num), sizeof((num)) * 2)

struct Bootelf_memmap_entry {
  u64 base;
  u64 size;
  u32 type;
  u32 acpi3type;
};

struct Bootelf_data {
  u64 magic;
  u64 numEntries;
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

  for(u32 i = 0; i < ptr->numEntries; ++ i) {
    print_value("Memmap entry ", i);
    print_value(" base:  ", ptr->entries[i].base);
    print_value(" size:  ", ptr->entries[i].size);
    print_value(" type:  ", ptr->entries[i].type);
    print_value(" acpi3: ", ptr->entries[i].acpi3type);
  }

  shutdown();
  while(1);
}
