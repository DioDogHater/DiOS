%ifndef ISR_ASM
%define ISR_ASM

%include "kernel/drivers/screen.nasm"

%include "kernel/interrupts/idt.nasm"
%include "kernel/interrupts/interrupts.nasm"

isr_setup:
    mov edi, 0
    mov edx, KDATA(isr_arr)

    .loop:
    mov eax, DWORD [edx]
    call set_idt_gate
    add edx, 4
    inc edi
    cmp edi, 32
    jb .loop

    call set_idt
    ret

isr_handler:
    ; High contrast to see clearly
    mov BYTE [KDATA(video_attribute)], LIGHT_RED_FG

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

    ; Reset video attribute
    mov BYTE [KDATA(video_attribute)], WHITE_ON_BLACK

    ret

    .text:
        db "RECEIVED INT ",0
    .text2:
        db " - ERR: ",0

; array of all isrs
isr_arr:
    dd KDATA(isr0)
    dd KDATA(isr1)
    dd KDATA(isr2)
    dd KDATA(isr3)
    dd KDATA(isr4)
    dd KDATA(isr5)
    dd KDATA(isr6)
    dd KDATA(isr7)
    dd KDATA(isr8)
    dd KDATA(isr9)
    dd KDATA(isr10)
    dd KDATA(isr11)
    dd KDATA(isr12)
    dd KDATA(isr13)
    dd KDATA(isr14)
    dd KDATA(isr15)
    dd KDATA(isr16)
    dd KDATA(isr17)
    dd KDATA(isr18)
    dd KDATA(isr19)
    dd KDATA(isr20)
    dd KDATA(isr21)
    dd KDATA(isr22)
    dd KDATA(isr23)
    dd KDATA(isr24)
    dd KDATA(isr25)
    dd KDATA(isr26)
    dd KDATA(isr27)
    dd KDATA(isr28)
    dd KDATA(isr29)
    dd KDATA(isr30)
    dd KDATA(isr31)

%endif
