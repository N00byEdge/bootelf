; Config end
elf_entry equ 24
elf_phoff equ elf_entry + 8
elf_phentsize equ elf_phoff + 8 + 8 + 4 + 2
elf_phnum equ elf_phentsize + 2

phdr_type equ 0
phdr_offset equ 8
phdr_vaddr equ phdr_offset + 8
phdr_filesz equ phdr_vaddr + 16
phdr_memsz equ phdr_filesz + 8

  mov r10, elf_load_base
  xor al, al

  ; Okay who cares about doing reasonable things?
  ; Just assume it's a valid ELF and that it does nothing bad
  mov r8, [r10 + elf_phoff]
  add r8, r10
  movzx r11, word [r10 + elf_phnum]
  movzx r9, word [r10 + elf_phentsize]

do_phdr:
  cmp byte [r8 + phdr_type], 1 ; dword theoretically but let's save bytes
  jne next_phdr

  mov rdi, [r8 + phdr_vaddr]
  mov rsi, [r8 + phdr_offset]
  add rsi, r10

  mov rcx, [r8 + phdr_filesz]
  mov r12, rcx
  rep movsb

  mov rcx, [r8 + phdr_memsz]
  sub rcx, r12
  rep stosb

next_phdr:
  add r8, r9
  dec r11
  jnz do_phdr

  mov rdi, bootelf
  mov dword[rdi], 0xb007e1f ; Bootelf version 0

  jmp [r10 + elf_entry]
