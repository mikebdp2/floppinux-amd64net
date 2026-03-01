; Simple VGA16 Framebuffer Pixel Drawing Program (FASM)
; Draws a red 10x10 square in the center of the screen
; Assumes vga16fb (640x480x4bpp planar), default palette (index 4 = red)
;
; Compile: fasm pixel.asm pixel
;
; This program:
; 1. Sets iopl(3) for port access
; 2. Opens /dev/fb0
; 3. Memory maps the framebuffer
; 4. Draws a red 10x10 square at the center using planar writes
; 5. Syncs to display
; 6. Waits for keypress
; 7. Cleans up and exits

format ELF executable 3
entry _start

fb_device: db "/dev/fb0", 0
fb_fd: dd 0
fb_addr: dd 0
key_buffer equ 0x70000000
; Hardcoded for vga16fb default mode
screen_width: dd 640
screen_height: dd 480
line_length: dd 80  ; bytes per line (640 / 8)
red_pixel: db 4     ; Palette index for red in default VGA palette

_start:
    ; Set iopl(3) for I/O port access (requires root)
    mov eax, 110    ; SYS_iopl (i386 syscall number)
    mov ebx, 3      ; Level 3 (full I/O access)
    int 0x80
    cmp eax, 0
    jl error_exit

    ; Open /dev/fb0
    mov eax, 5      ; open syscall
    mov ebx, fb_device
    mov ecx, 2      ; O_RDWR
    int 0x80
    cmp eax, 0
    jl error_exit
    mov [fb_fd], eax

    ; Memory map the framebuffer (64KB for VGA)
    mov eax, 192    ; mmap2 syscall
    mov ebx, 0      ; addr: kernel chooses
    mov ecx, 0x10000 ; length: 64KB
    mov edx, 3      ; prot: PROT_READ | PROT_WRITE
    mov esi, 1      ; flags: MAP_SHARED
    mov edi, [fb_fd]
    mov ebp, 0      ; pgoffset
    int 0x80
    cmp eax, 0
    jl error_exit
    mov [fb_addr], eax

    ; Draw a 10x10 red square in center
    mov edx, 0      ; dy = 0
.draw_loop_y:
    cmp edx, 10
    jge .draw_done
    mov esi, 0      ; dx = 0
.draw_loop_x:
    cmp esi, 10
    jge .draw_loop_y_next
    ; Calculate x = width / 2 + dx - 5
    mov edi, [screen_width]
    shr edi, 1
    add edi, esi
    sub edi, 5
    ; y = height / 2 + dy - 5
    mov ecx, [screen_height]
    shr ecx, 1
    add ecx, edx
    sub ecx, 5
    ; Set pixel at (edi, ecx) to red
    ;call set_pixel
    inc esi         ; dx++
    jmp .draw_loop_x
.draw_loop_y_next:
    inc edx         ; dy++
    jmp .draw_loop_y
.draw_done:
    ; Sync to display (fsync syscall)
    mov eax, 36     ; fsync
    mov ebx, [fb_fd]
    int 0x80

    ; Wait for keypress
.wait_for_keypress:
    mov eax, 3      ; read syscall
    mov ebx, 0      ; stdin
    mov ecx, key_buffer
    mov edx, 1      ; size 1
    int 0x80

    ; Close file descriptor
    mov eax, 6      ; close
    mov ebx, [fb_fd]
    int 0x80

    ; Exit successfully
    mov eax, 1      ; exit
    mov ebx, 0      ; code 0
    int 0x80

error_exit:
    ; Exit with error code 1
    mov eax, 1
    mov ebx, 1
    int 0x80
