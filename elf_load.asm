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

  xor ebx, ebx
  mov bh, elf_load_base >> 8

  ; Okay who cares about doing reasonable things?
  ; Just assume it's a valid ELF and that it does nothing bad
  mov edx, [rbx + elf_phoff]
  add edx, ebx
  movzx ebp, word [rbx + elf_phnum]

do_phdr:
  cmp dword [rdx + phdr_type], 1
  jne next_phdr

  mov rdi, [rdx + phdr_vaddr]
  mov esi, [rdx + phdr_offset]
  add esi, ebx

  mov eax, [rdx + phdr_memsz]
  mov ecx, [rdx + phdr_filesz]
  sub eax, ecx
  rep movsb

  xchg eax, ecx
  rep stosb

next_phdr:
  movzx eax, word [rbx + elf_phentsize]
  add edx, eax
  dec ebp
  jnz do_phdr

  mov edi, bootelf
  mov dword[rdi], 0xb007e1f ; Bootelf version 0

  jmp [rbx + elf_entry]
