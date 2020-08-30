#include <stdbool.h>

char *vga = (char *)0xB8000;
bool enable_e9 = false;

void outb(unsigned short port, char val) {
  asm volatile (
    "outb %[val], %[port]\n\t"
    :
    : [val] "al" (val), [port] "dx" (port)
  );
}

void my_putchar(char val) {
  *vga++ = val;
  *vga++ = 0x20;
}

void clear_screen(void) {
  int i;
  for(i = 0; i < 80 * 25; ++ i)
    my_putchar(' ');
  vga = (char *)0xB8000;
}

void my_printstring(char const *val) {
  while(*val) {
    outb(0xE9, *val);
    my_putchar(*val++);
  }
}

void shutdown(void) {
  outb(0x64, 0xFE);
}

int _start() {
  clear_screen();
  enable_e9 = true;
  my_printstring("PASS!");
  outb(0xE9, '\n');
  shutdown();
  while(1);
}
