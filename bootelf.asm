elf_load_base equ 0x7E00

elf_entry equ 24
elf_phoff equ elf_entry + 8
elf_phentsize equ elf_phoff + 8 + 8 + 4 + 2
elf_phnum equ elf_phentsize + 2

phdr_type equ 0
phdr_offset equ 8
phdr_vaddr equ phdr_offset + 8
phdr_filesz equ phdr_vaddr + 16
phdr_memsz equ phdr_filesz + 8

page_table equ 0x03
mapping_2m equ 0x83

dl_save equ 0x0FF0

; Page tables will be zeroed together with this memory
bootelf equ 0x5000
bootelf_memmap_num equ bootelf + 8
bootelf_memmap_entries equ bootelf + 16

memmap_location equ bootelf + 0x100
ebx_save equ bootelf + 0x200

[bits 16]
org 0x7C00
_start:
  xor bx, bx
  mov ds, bx

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

  ; Clear page tables
  xor di, di
  xor al, al
  lea cx, [0x5000]
  rep stosb

  ; Now let's get the memory map
  xor bp, bp ; Entry count
  mov es, bp
  mov [ebx_save], bp ; Zero out ebx save
  mov di, memmap_location
  mov word [bootelf_memmap_entries], di
  xor ecx, 24

memmap_loop:
  mov eax, 0xE820
  mov ebx, [ebx_save]
  mov ecx, 24
  mov edx, 0x534D4150

  mov byte[di + 20], 1

  int 0x15

  jc stopmemmap

  mov [ebx_save], ebx
  add di, 24
  inc bp

  test ebx, ebx
  jz stopmemmap

  jmp memmap_loop

stopmemmap:
  mov [bootelf_memmap_num], bp

  ; We have now abused the BIOS as much as we need/want to.
  ; Time to go to 64 bits.
  cli
  lgdt [gdtr]

  mov eax, 0x1000
  mov word [eax + 0x000], page_table + 0x2000 ; Write page table root
  mov word [eax + 0xFF8], page_table + 0x2000 ; Upper half is same
  mov cr3, eax
  mov word [0x2000], page_table + 0x3000 ; First G
  mov word [0x2008], page_table + 0x4000 ; Second G
  mov word [0x2FF0], page_table + 0x3000 ; -2G
  mov word [0x2FF8], page_table + 0x4000 ; -1G

  ; Indentity map bottom 2G
  mov di, 0x3000
  xor ax, ax
  mov cx, 0x400
moremappings:
  mov word [di], mapping_2m ; Third level
  mov word [di + 3], ax
  add di, 8
  add ax, 2
  loop moremappings

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

gdtr:
dw 8 * 2 - 1 ; Really who cares but sure
dd gdt - 8

gdt:
  ; Descriptor 0x08, the only descriptor
  dq 0x00A09A0000000000

times 510-($-$$) db 0
dw 0xaa55
