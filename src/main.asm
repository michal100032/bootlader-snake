org 0x7C00
bits 16

entry:
    .set_video_mode:
        mov ax, 13h     ; 320x200 visual mode
        int 10h
    
    .save_video_memory_segment:
        push VIDEO_MEMORY_SEGMENT_ADDRESS
        pop es
    .set_input_handler:
        cli
        ; interrpt 9, 4 * 9 = 36
        mov [36], word handle_input
        mov [38], cs
        sti

    mov ax, 0x0008    
    mov [SNAKE_OFFSET_ADDRESS], ax

main_loop:    
    .move_snake:
        mov cx, [snake_set_velocity]
        mov [snake_velocity], cx
        mov ax, [SNAKE_OFFSET_ADDRESS]
        add al, cl
        add ah, ch

    .clamp_y:    
        cmp al, 0
        jl .clamp_y_min
        cmp al, 0x9 
        jle .clamp_y_done
        mov al, 0
        jmp .clamp_y_done
    .clamp_y_min:
        mov al, 0x9
    .clamp_y_done:

    .clamp_x:
        cmp ah, 0
        jl .clamp_x_min
        cmp ah, 0x0f
        jle .clamp_x_done
        mov ah, 0
        jmp .clamp_x_done
    .clamp_x_min:
        mov ah, 0xf
    .clamp_x_done:
    ; ax - next snake position
    call check_collision
    test cx, cx
    jnz game_over

    mov [SNAKE_OFFSET_ADDRESS], ax


    .check_for_fruit:
        cmp ax, [fruit]
        jne .fruit_check_end
    .eat_fruit_loop:
        add word [snake_len], 2
        inc byte [score]

    .generate_new_apple:
        mov al, 11
        mul byte [fruit_number]
        mov bh, 10
        div bh
        mov byte [fruit.y], ah

        mov al, 23
        mul byte [fruit_number]
        mov bl, 9
        div bl
        mov byte [fruit.x], ah
        
        inc byte [fruit_number]

        mov ax, [fruit]
        call check_collision
        test cx, cx
        jnz .generate_new_apple

    .fruit_check_end:

    .move_snake_in_mem:
        mov bx, [snake_len]
    .move_snake_in_mem_loop:
        mov cx, [SNAKE_OFFSET_ADDRESS - 2 + bx]
        mov [SNAKE_OFFSET_ADDRESS + bx], cx
        
        dec bx
        dec bx
        jnz .move_snake_in_mem_loop

    
    .clear_screen:
        mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    .clear_screen_loop:
        mov di, cx
        mov byte [es:di - 1], COLOR_BLACK
        loop .clear_screen_loop

    .draw_fruit:
        push word COLOR_LIGHT_RED
        push word [fruit]
        call draw_square

    .draw_snake:
        mov bx, [snake_len]
        push word COLOR_WHITE
    .draw_snake_loop:        
        push word [SNAKE_OFFSET_ADDRESS + bx]
        call draw_square
        pop dx

        dec bx
        dec bx
        jnz .draw_snake_loop

    add sp, 6

    .draw_score:
        movzx ax, byte [score]
        mov bl, 10
        div bl
        push ax
        mov dx, 0x0114
    .draw_score_loop:
        
        mov bh, 0                       ; Page zero
        mov ax, 0200h                   ; Move cursor
        int 10h
        
        pop ax
        add al, '0'
        push ax
        mov bl, 0x0F
        mov ah, 0Ah                     ; Plot char
        mov cl, 1                       ; Repeat once
        int 10h
        pop ax
        shr ax, 8
        push ax
        inc dx
        cmp dx, 0x0116
        jb .draw_score_loop

    pop ax

    .delay:
        mov ah, 86h
        mov cx, 2      ; hardcoded delay             
        mov dx, 0000
        int 15h

    jmp main_loop

game_over:
    jmp 0FFFFh:0 

; input in ax
; return value in cx
check_collision:
    push bx
    xor cx, cx
    mov bx, [snake_len]
    .check_collision_loop:
        dec bx
        dec bx

        cmp ax, [SNAKE_OFFSET_ADDRESS + bx]
        je .collision
        
        test bx, bx
        jz .return
        jmp .check_collision_loop
        
    .collision:
        mov cx, 1
    .return:
        pop bx
        ret

; arguments are pushed to the stack
; [bp+4] - square code (higher 8 bits = x, lower 8 bits = y)
; [bp+6] - color  
draw_square:
    push bp ; same as enter 0, 0 but enter uses one byte more
    mov bp, sp
    pusha

    .calculate_screen_x_and_y:
    mov bx, GRID_SQAURE_SIZE        ; bh = 0, bl = GRID_SQUARE_SIZE
    .calculate_x:
        mov al, [bp+5]
        mul bl
        push ax
    .calculate_y:
        mov al, [bp+4]
        mul bl
    
    ; mov ax, 0
    mov dx, SCREEN_WIDTH
    mul dx
    pop dx
    add ax, dx
    dec bx
    ; ax = first pixel of the square

    mov dl, [bp+6]
    .draw_loop:
        mov cx, GRID_SQAURE_SIZE - 1
    .draw_row_loop:
        mov di, ax
        mov [es:di], dl
        
        ; move to the next pixel
        inc ax
        loop .draw_row_loop

        ; move to the next line
        add ax, SCREEN_WIDTH - GRID_SQAURE_SIZE + 1
        dec bx
        jnz .draw_loop

    popa

    mov sp, bp
    pop bp
    ret
    
handle_input:
    pusha

    in al, KEYBOARD_PORT
    
    mov bx, [snake_velocity]
    test bh, bh
    jz .input_x
    .input_y:
        cmp al, keycode.W
        je .input_up
        cmp al, keycode.S
        je .input_down

        jmp .return
    .input_x:
        cmp al, keycode.A
        je .input_left
        cmp al, keycode.D
        je .input_right
    
        jmp .return

    .input_up:
        mov bx, VELOCITY_UP
        jmp .input_done
    .input_down:
        mov bx, VELOCITY_DOWN
        jmp .input_done
    .input_left:
        mov bx, VELOCITY_LEFT
        jmp .input_done
    .input_right:
        mov bx, VELOCITY_RIGHT
    .input_done:
        mov [snake_set_velocity], bx

    
    .return:
    mov al, 61h
    out 20h, al

    popa
    iret

data:

snake_len:                      dw  2
snake_velocity:                 dw  0x0100
snake_set_velocity:             dw  0x0100

SNAKE_OFFSET_ADDRESS            equ 7E0h
VIDEO_MEMORY_SEGMENT_ADDRESS    equ 0A000h
GRID_SQAURE_SIZE                equ 20

SCREEN_WIDTH                    equ 320
SCREEN_HEIGHT                   equ 200

COLOR_WHITE                     equ 0Fh
COLOR_BLACK                     equ 0
COLOR_LIGHT_RED                 equ 0Ch

VELOCITY_RIGHT                  equ 0x0100
VELOCITY_LEFT                   equ 0xff00
VELOCITY_DOWN                   equ 0x0001
VELOCITY_UP                     equ 0x00ff  

keycode:
    .W                  equ 11h
    .A                  equ 1Eh
    .S                  equ 1Fh
    .D                  equ 20h

fruit:
    .y                  db  7
    .x                  db  8

fruit_number:           db  10
score:                  db  0

KEYBOARD_PORT           equ 60h


%assign size $-$$
%warning Size: size bytes

times 510-size db 0
dw 0AA55h