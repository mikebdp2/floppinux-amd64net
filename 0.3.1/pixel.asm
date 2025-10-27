; Simple VESA Framebuffer Pixel Drawing Program (FASM)
; Draws a red 10x10 square in the center of the screen
;
; Compile: fasm pixel.asm pixel
;
; This program:
; 1. Opens /dev/fb0
; 2. Memory maps the framebuffer
; 3. Draws a red 10x10 square at the center
; 4. Syncs to display
; 5. Cleans up and exits

format ELF executable 3
entry _start

fb_device:      db "/dev/fb0", 0
fb_fd:          dd 0
fb_addr:        dd 0

; Default VESA resolution (1024x768)
screen_width:   dd 1024
screen_height:  dd 768

; Pixel data: BGRA format (Blue, Green, Red, Alpha)
red_pixel:      dd 0xFF0000FF  ; Red in BGRA

_start:
    ; Open /dev/fb0
    mov eax, 5              ; open syscall
    mov ebx, fb_device      ; path to /dev/fb0
    mov ecx, 2              ; flags: O_RDWR
    int 0x80

    cmp eax, 0              ; check for error
    jl error_exit

    mov [fb_fd], eax        ; save file descriptor

    ; Memory map the framebuffer
    ; mmap2 syscall (syscall 192)
    mov eax, 192            ; mmap2 syscall number
    mov ebx, 0              ; addr: let kernel choose
    mov ecx, 0x1000000      ; length: ~16MB
    mov edx, 3              ; prot: PROT_READ | PROT_WRITE
    mov esi, 1              ; flags: MAP_SHARED
    mov edi, [fb_fd]        ; fd
    mov ebp, 0              ; pgoffset
    int 0x80

    cmp eax, 0              ; check for error
    jl error_exit

    mov [fb_addr], eax      ; save mapped address

    ; Draw a 10x10 red square in center
    mov edx, 0              ; dy = 0

.draw_loop_y:
    cmp edx, 10             ; if dy >= 10, exit loop
    jge .draw_done

    mov esi, 0              ; dx = 0

.draw_loop_x:
    cmp esi, 10             ; if dx >= 10, go to next row
    jge .draw_loop_y_next

    ; Calculate center coordinates
    mov eax, [screen_height]
    shr eax, 1              ; eax = height / 2
    add eax, edx            ; eax = center_y + dy

    mov ebx, [screen_width]
    imul eax, ebx           ; eax = (center_y + dy) * width
    shl eax, 2              ; eax = eax * 4 (bytes per pixel)

    ; Add x offset
    mov ebx, [screen_width]
    shr ebx, 1              ; ebx = width / 2
    add ebx, esi            ; ebx = center_x + dx
    shl ebx, 2              ; ebx = ebx * 4
    add eax, ebx            ; eax = final offset

    ; Write pixel to framebuffer
    mov ebx, [fb_addr]      ; ebx = framebuffer base address
    add ebx, eax            ; ebx points to pixel location
    mov eax, [red_pixel]    ; eax = red color (0xFF0000FF)
    mov [ebx], eax          ; write pixel

    inc esi                 ; dx++
    jmp .draw_loop_x

.draw_loop_y_next:
    inc edx                 ; dy++
    jmp .draw_loop_y

.draw_done:
    ; Sync to display (fsync syscall)
    mov eax, 36             ; fsync syscall
    mov ebx, [fb_fd]        ; file descriptor
    int 0x80

    ; Close file descriptor
    mov eax, 6              ; close syscall
    mov ebx, [fb_fd]        ; file descriptor
    int 0x80

    ; Exit successfully
    mov eax, 1              ; exit syscall
    mov ebx, 0              ; exit code 0
    int 0x80

error_exit:
    ; Exit with error code 1
    mov eax, 1              ; exit syscall
    mov ebx, 1              ; exit code 1
    int 0x80
