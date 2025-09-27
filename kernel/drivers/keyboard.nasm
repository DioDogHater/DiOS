%ifndef __DRIVER_KEYBOARD_NASM
%define __DRIVER_KEYBOARD_NASM

%include "kernel/drivers/ports.nasm"
%include "kernel/drivers/screen.nasm"
%include "stdlib/lib.nasm"

%define SCANCODE_ESC 0x01
%define SCANCODE_LSHIFT 0x2A
%define SCANCODE_RSHIFT 0x36
%define SCANCODE_CAPSLOCK 0x3A
%define SCANCODE_ENTER 0x1C
%define SCANCODE_BACKSPACE 0x0E
%define SCANCODE_UP 0x68
%define SCANCODE_DOWN 0x70
%define SCANCODE_LEFT 0x6B
%define SCANCODE_RIGHT 0x6D

keybuffer_len equ 256
keybuffer:
    times keybuffer_len db 0
keybuffer_cursor:
    dd 0

keyboard_callback:
    cmp BYTE [KDATA(.ignore)], 0
    jz .dont_ignore
    mov BYTE [KDATA(.ignore)], 0
    jmp .end
    .dont_ignore:

    xor eax, eax
    port_byte_in 0x60

    cmp al, 0xE0
    jne .not_special_key
    port_byte_in 0x60
    mov BYTE [KDATA(.ignore)], 1

    cmp al, 0x48
    je .arrow_key
    cmp al, 0x50
    je .arrow_key
    cmp al, 0x4B
    je .arrow_key
    cmp al, 0x4D
    jne .end

    .arrow_key:
    mov bl, al
    and bl, 0x80
    rol bl, 1
    xor bl, 0x01
    add al, 0x20
    mov BYTE [KDATA(keyboard_map)+eax], bl
    jmp .end

    .not_special_key:

    mov bl, al
    cmp al, SCANCODE_CAPSLOCK
    je .toggle_caps
    and al, 0x7F
    cmp al, SCANCODE_LSHIFT
    je .toggle_caps
    cmp al, SCANCODE_RSHIFT
    jne .dont_toggle_caps

    .toggle_caps:
    xor BYTE [KDATA(shift_on)], 0x01

    .dont_toggle_caps:
    mov al, bl
    and bl, 0x80
    test bl, bl

    jnz .released

    .pressed:
    mov BYTE [KDATA(keyboard_map)+eax], 1

    cmp al, SCANCODE_ENTER
    jne .not_enter

    call kernel_input
    mov BYTE [KDATA(keybuffer)], 0
    mov DWORD [KDATA(keybuffer_cursor)], 0
    jmp .end
    .not_enter:

    cmp al, SCANCODE_BACKSPACE
    jne .normal_key

    mov edi, DWORD [KDATA(keybuffer_cursor)]
    test edi, edi
    jz .end
    dec edi
    mov BYTE [KDATA(keybuffer)+edi], 0
    mov DWORD [KDATA(keybuffer_cursor)], edi

    call get_cursor_offset
    sub bx, 2
    call set_cursor_offset
    mov ax, bx
    mov bl, ' '
    disable_cursor
    call kputchar_offset
    enable_cursor
    jmp .end
    .normal_key:

    mov bh, BYTE [KDATA(shift_on)]
    test bh, bh
    jz .dont_shift_char
    mov bl, BYTE[KDATA(US_layout+1)+eax*2]
    jmp .end_shift_char

    .dont_shift_char:
    mov bl, BYTE [KDATA(US_layout)+eax*2]

    .end_shift_char:

    cmp bl, 7
    je .end

    call kputchar

    mov edi, DWORD [KDATA(keybuffer_cursor)]
    cmp edi, keybuffer_len
    jge .end
    mov BYTE [KDATA(keybuffer)+edi], bl
    inc edi
    mov BYTE [KDATA(keybuffer)+edi], 0
    mov DWORD [KDATA(keybuffer_cursor)], edi


    jmp .end

    .released:
    and al, 0x7F
    mov BYTE [KDATA(keyboard_map)+eax], 0

    .end:
    ret

    .ignore:
    db 0

init_keyboard:
    mov edi, 1
    mov eax, KDATA(keyboard_callback)
    call set_irq_handler
    ret

keyboard_map:
    times 128 db 0

shift_on:
    db 0

US_layout:
    db 7,7,27,27
    db "1!2@3#4$5%6?7&8*9(0)-_=+"
    db 8,8,9,9
    db "qQwWeErRtTyYuUiIoOpP[{]}"
    db 10,10,7,7
    db "aAsSdDfFgGhHjJkKlL;:"
    db 39, 34
    db "`^"
    db 7,7
    db "\|zZxXcCvVbBnNmM,<.>/~"
    db 7,7
    db "**"
    db 7,7
    db "  "
    db 7,7,7,7,7,7,7,7,7,7,7,7,7
    db 7,7,7,7,7,7,7,7,7,7,7,7,7
    db "778899--445566++11223300.."
    db 7,7,7,7,7
    db 7,7,7,7,7
    times 256 - ($ - US_layout) db 7

%endif
