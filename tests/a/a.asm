[bits 64]

; Just a few sections to make sure they all load at the proper locations
section .rodata
pass_location:
dq 0xB8000 + 10 * 80 * 2 + 39 * 2

section .data
fb_location:
dq 0xB8000

section .text
global _start
_start:
  mov ax, 0x2020
  mov rcx, 80 * 25
  ; Relative addressing
  mov rdi, [rel fb_location]

  rep stosw

  ; Absolute addressing
  mov rdi, [pass_location]
  mov al, 'P'
  stosw
  mov al, 'A'
  stosw
  mov al, 'S'
  stosw
  stosw
  jmp $
