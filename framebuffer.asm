; Use this if we don't get a valid resolution from edid
default_width equ 1024
default_height equ 768

; Use edid instead of just straight up always using the default resolution
; Saves a decent amount of bytes
%define use_edid

; EDID giving a width or height as 0 should be treated as a failure
; Here we can decide if we only check the height to save a few bytes
; Irrelevant if we're not using edid to begin with
%define check_edid_width

; Config end

bootelf_fb equ bootelf + 24

fb_buf equ bootelf + 0x210

bootelf_fb_addr equ bootelf_fb + 0
bootelf_fb_pitch equ bootelf_fb + 8
bootelf_fb_width equ bootelf_fb + 12
bootelf_fb_height equ bootelf_fb + 16

edid_timing_offset equ 54

vesa_attribute_offset equ 0
vesa_pitch_offset equ 16
vesa_width_offset equ 18
vesa_height_offset equ 20
vesa_bpp_offset equ 25
vesa_memory_model_offset equ 27
vesa_framebuffer_offset equ 40

%ifmacro use_edid
  mov di, fb_buf
  mov ax, 0x4F15
  push 1
  pop dx

  int 0x10

  ; display width
  mov dh, [di + edid_timing_offset + 4]
  shr dh, 4
  mov dl, [di + edid_timing_offset + 2]

  ; display height
  mov bh, [di + edid_timing_offset + 7]
  shr bh, 4
  mov bl, [di + edid_timing_offset + 5]

  ; Check if either height or width is zero, and if so, fallback to a default resolution

  %ifmacro check_edid_width
    cmp dx, dx
    jz getanyvideo
  %endif

    cmp bx, bx
    jnz getvideo
%endif
  
getanyvideo:
  mov dx, default_width
  mov bx, default_height

getvideo:
  mov [bootelf_fb_width], dx
  mov [bootelf_fb_height], bx

  ; Brute force the video mode for this resolution
  mov cx, 0xFFFF

get_video_loop:
  inc cx
  js done ; Check if we've run out of video modes to test

  mov ax, 0x4f01
  mov di, fb_buf
  int 0x10

  ; Check if the video mode is the correct one
  cmp dx, [di + vesa_width_offset]
  jne get_video_loop

  cmp bx, [di + vesa_height_offset]
  jne get_video_loop

  cmp byte [di + vesa_bpp_offset], 32
  jne get_video_loop

  ; Check that it's a linear mode
  bt word [di + vesa_attribute_offset], 7
  jnc get_video_loop

  ; Check that it's not text mode
  cmp word [di + vesa_memory_model_offset], 0x06
  jne get_video_loop

  ; We got it!
  mov bx, [di + vesa_pitch_offset]
  mov [bootelf_fb_pitch], bx

  mov eax, [di + vesa_framebuffer_offset]
  mov [bootelf_fb_addr], eax

  ; Set the mode
  mov bx, cx
  bts bx, 14
  mov ax, 0x4f02
  int 0x10

done:
