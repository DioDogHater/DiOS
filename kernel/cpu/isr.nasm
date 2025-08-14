%ifndef ISR_ASM
%define ISR_ASM

%include "kernel/drivers/ports.nasm"
%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/idt.nasm"
%include "kernel/cpu/interrupts.nasm"

isr_setup:
    mov edi, 0
    mov edx, KDATA(isr_stub_table)

    .isr_loop:
    mov eax, DWORD [edx]
    call set_idt_gate
    add edx, 4
    inc edi
    cmp edi, 32
    jb .isr_loop

    port_byte_out 0x20, 0x11
    port_byte_out 0xA0, 0x11
    port_byte_out 0x21, 0x20
    port_byte_out 0xA1, 0x28
    port_byte_out 0x21, 0x04
    port_byte_out 0xA1, 0x02
    port_byte_out 0x21, 0x01
    port_byte_out 0xA1, 0x01
    port_byte_out 0x21, 0x00
    port_byte_out 0xA1, 0x00

    port_byte_out 0x21, 0x00
    port_byte_out 0xA1, 0x00

    mov edi, 32
    mov edx, KDATA(irq_stub_table)

    .irq_loop:
    mov eax, DWORD [edx]
    call set_idt_gate
    add edx, 4
    inc edi
    cmp edi, 48
    jb .irq_loop

    call set_idt
    ret

isr_handler:
    ; High contrast to see clearly
    set_video_attribute(LIGHT_RED_FG)

    ; Print out the isr's data
    mov edi, KDATA(.text)
    call kprint_str

    xor edx, edx
    mov dl, BYTE [esp+40]
    call kprint_dec_offset

    mov edi, KDATA(.text2)
    call kprint_str_offset

    mov dl, BYTE [esp+41]
    call kprint_dec_offset

    mov bl, 10
    call kputchar_offset

    set_video_default
    ret

    .text:
    db "RECEIVED INT ",0
    .text2:
    db " - ERR: ",0

irq_handler:
    mov dl, BYTE [esp+40]
    cmp dl, 40
    jb .no_eoi
    port_byte_out 0xA0, 0x20
    .no_eoi:
    port_byte_out 0x20, 0x20

    movzx edi, BYTE [esp+41]
    mov edx, DWORD [KDATA(irq_callback)+edi*4]
    test edx, edx
    jz .end
    call edx

    .end:
    ret

; edi - irq number
; eax - callback
set_irq_handler:
    mov DWORD [KDATA(irq_callback)+edi*4], eax
    ret

irq_callback:
    resd 16

%endif
