elf_load_base equ 0x7E00

dl_save equ 0x0FF0

bootelf equ 0x5000

[bits 16]
org 0x7C00
_start:
  xor bx, bx
  mov ds, bx
  mov ss, bx

  ; Read ELF file from disk
  mov bp, elf_load_base/0x10 - 0x20

  mov dh, 0          ; Head 0
  mov cx, 0x0001     ; Cylinder 0, sector 1
disk_read_loop:
  add cl, 1
  jc stopread
  add bp, 0x20
  mov es, bp
  mov ax, 0x0201     ; Number of sectors to read (al) = 1
                     ; Command                   (ah) = 2 (Read Sectors From Drive)
  int 0x13
  ; Hey, that worked. Cool.
  ; Let's just continue reading until we hit some error.
  jnc disk_read_loop
stopread:

  ; Clear memory we assume is zeroed
  mov di, 0x800
  xor al, al
  lea cx, [0x7C00 - 0x800]
  rep stosb

  %include "memmap.asm"

  ; Comment out to skip getting a framebuffer
  %include "framebuffer.asm"

  ; We have now abused the BIOS as much as we need/want to.
  ; Time to go to 64 bits.
  cli
  lgdt [gdtr]

  %include "paging.asm"

  mov eax, cr4
  or al, (1 << 5)
  mov cr4, eax

  mov ecx, 0xc0000080
  or ax, (1 << 8)
  wrmsr

  mov eax, 0x80000011
  mov cr0, eax

  jmp 0x08:bits64

[bits 64]
bits64:
  ; No reason to reload ds as base and limit is ignored
  %include "elf_load.asm"

gdtr:
dw 8 * 2 - 1 ; Really who cares but sure
dd gdt - 8

gdt:
  ; Descriptor 0x08, the only descriptor
  dq 0x00A09A0000000000

times 510-($-$$) db 0
dw 0xaa55
