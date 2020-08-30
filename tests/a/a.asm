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

  ; Print a string
  mov al, 'P'
  call putch
  mov al, 'A'
  call putch
  mov al, 'S'
  call putch
  call putch
  mov al, '!'
  call putch
  mov al, 0x0a
  out 0xE9, al

  ; Shutdown
  mov al, 0xFE
  out 0x64, al
  jmp $

putch:
  out 0xE9, al
  stosw
  ret
