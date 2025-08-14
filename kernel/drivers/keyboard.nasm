%ifndef KEYBOARD_ASM
%define KEYBOARD_ASM

keyboard_callback:
    xor eax, eax
    port_byte_in 0x60
    push eax
    mov edx, eax

    disable_cursor
    mov eax, MAX_COLS*6+128
    call kprint_dec_offset
    enable_cursor

    pop eax
    mov bl, BYTE [KDATA(US_layout)+eax]
    call kputchar

    mov edi, KDATA(.text)
    call kprint_str

    ret

    .text:
    db "KB",0

init_keyboard:
    mov ax, MAX_COLS*16
    mov edi, KDATA(.text)
    call kprint_str_offset

    mov edi, 1
    mov eax, KDATA(keyboard_callback)
    call set_irq_handler
    ret

    .text:
    db "Keyboard enabled!",10,0

US_layout:
    db 7,27
    db "1234567890-="
    db 8,9
    db "qwertyuiop[]"
    db 10,14
    db "asdfghjkl;"
    db 34
    db '`'
    db 15
    db "\zxcvbnm,./"
    db 15
    db '*'
    db 12
    db ' '
    db 16,7,7,7,7,7,7,7,7,7,7,7,7
    db "789-456+1230."
    db 7,7,7,7,7

%endif
