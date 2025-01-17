elf_load_base equ 0x7E00
elf_num_blocks equ (0x80000 - 0x7E00) / 0x200

bootelf equ 0x7000

[bits 16]
org 0x7C00
_start:
  xor bx, bx
  mov ds, bx
  mov ss, bx
  mov cx, elf_num_blocks

  ; Read ELF file from disk
disk_read_loop:
  mov si, dap
  add word [si + dap.segment - dap], 0x20

  inc dword [si + dap.lba - dap]
  push dx
  mov ah, 0x42
  int 0x13
  pop dx

  jc stopread
  loop disk_read_loop
stopread:

  ; Clear memory we assume is zeroed
  mov di, 0x800
  xor al, al
  mov cx, 0x7C00 - 0x800
  rep stosb
  mov word [di], 0xa09a

  %include "memmap.asm"

  ; Comment out to skip getting a framebuffer
  %include "framebuffer.asm"

  ; We have now abused the BIOS as much as we need/want to.
  ; Time to go to 64 bits.
  cli
  lgdt [gdtr]

  %include "paging.asm"

  mov eax, cr4
  or al, 0xA3
  mov cr4, eax

  mov ecx, 0xc0000080
  rdmsr
  or ax, (1 << 8)
  wrmsr

  mov eax, 0x80000011
  mov cr0, eax

  jmp 0x08:bits64

dap:
  dw 16
  dw 1
  .offset: dw 0x7C00
  .segment: dw 0
  .lba: dq 0

[bits 64]
bits64:
  ; No reason to reload ds as base and limit is ignored
  %include "elf_load.asm"

gdtr equ $ - 2
  dd 0x7c00 - 5 - 8

times 510-($-$$) db 0
dw 0xaa55
