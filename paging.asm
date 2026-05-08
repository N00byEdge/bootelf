; Config end
page_table equ 0x03
mapping_2m equ 0x83

  mov eax, 0x1000
  mov word [eax + 0x000], page_table | 0x2000 ; Write page table root
  mov word [0x1FF8], page_table | 0x2000 ; Upper half is same
  mov cr3, eax

  mov bx, 0x2018
  mov ax, 0x6003
morel1map:
  mov word [bx], ax
  sub ah, 0x10
  sub bl, 8
  jnb morel1map

  mov word [0x2FF0], page_table | 0x3000 ; -2G
  mov word [0x2FF8], page_table | 0x4000 ; -1G

  ; Indentity map bottom 2G
  mov di, 0x3000
  xor ax, ax
moremappings:
  mov byte [di], mapping_2m ; Third level
  mov word [di + 2], ax
  add di, 8
  add ax, 32
  jnc moremappings
