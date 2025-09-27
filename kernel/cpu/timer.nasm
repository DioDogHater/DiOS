%ifndef __CPU_TIMER_NASM
%define __CPU_TIMER_NASM

%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/isr.nasm"

time_tick:
    dq 0

timer_callback:
    mov edx, DWORD [KDATA(time_tick)]
    inc edx
    mov DWORD [KDATA(time_tick)], edx
    mov edx, DWORD [KDATA(time_tick)+4]
    adc edx, 0
    mov DWORD [KDATA(time_tick)+4], edx
    ret

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
