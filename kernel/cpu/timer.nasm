%ifndef TIMER_ASM
%define TIMER_ASM

%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/isr.nasm"

time_tick:
    dd 0

timer_callback:
    disable_cursor
    mov eax, MAX_COLS*6
    mov edi, KDATA(.text)
    call kprint_str_offset

    mov edx, DWORD [KDATA(time_tick)]
    inc edx
    call kprint_dec_offset
    mov DWORD [KDATA(time_tick)], edx

    enable_cursor
    ret

    .text:
    db "TIMER: ",0

; ebx - frequency
init_timer:
    push ebx
    mov edi, 0
    mov eax, KDATA(timer_callback)
    call set_irq_handler

    pop ebx
    xor edx, edx
    mov eax, 1193180
    div ebx
    push ax
    port_byte_out 0x43, 0x36
    out 0x40, al
    shr ax, 8
    out 0x40, al
    pop ax

    ret

%endif
