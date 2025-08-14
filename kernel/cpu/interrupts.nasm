%ifndef INTERRUPTS_ASM
%define INTERRUPTS_ASM

%include "kernel/cpu/isr.nasm"

; Macros for isr handlersS
%macro isr_err_stub 1
isr_stub_%+%1:
    cli
    push byte %1
    jmp isr_common_stub
%endmacro
%macro isr_no_err_stub 1
isr_stub_%+%1:
    cli
    push byte 0
    push byte %1
    jmp isr_common_stub
%endmacro

%macro _irq_stub 1
irq_stub_%+%1:
    cli
    push byte %1
    push byte %1+32
    jmp irq_common_stub
%endmacro

; ---------------- Copied code from ----------------------
; https://github.com/cfenollosa/os-tutorial/blob/master/18-interrupts/cpu/interrupt.asm

; Common ISR code
isr_common_stub:
    ; 1. Save CPU state
	pusha ; Pushes edi,esi,ebp,esp,ebx,edx,ecx,eax
	mov ax, ds ; Lower 16-bits of eax = ds.
	push eax ; save the data segment descriptor
	mov ax, 0x10  ; kernel data segment descriptor
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

    ; 2. Call interrupt handler
	call isr_handler

    ; 3. Restore state
	pop eax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	popa
	add esp, 8 ; Cleans up the pushed error code and pushed ISR number
	sti
	iret ; pops 5 things at once: CS, EIP, EFLAGS, SS, and ESP

; Common IRQ code. Identical to ISR code except for the 'call'
; and the 'pop ebx'
irq_common_stub:
    pusha
    mov ax, ds
    push eax
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call irq_handler ; Different than the ISR code

    pop ebx  ; Different than the ISR code
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    popa
    add esp, 8
    sti
    iret

; ------- end of copied code ---------


; Code from https://wiki.osdev.org/Interrupts_Tutorial

isr_no_err_stub 0
isr_no_err_stub 1
isr_no_err_stub 2
isr_no_err_stub 3
isr_no_err_stub 4
isr_no_err_stub 5
isr_no_err_stub 6
isr_no_err_stub 7
isr_err_stub    8
isr_no_err_stub 9
isr_err_stub    10
isr_err_stub    11
isr_err_stub    12
isr_err_stub    13
isr_err_stub    14
isr_no_err_stub 15
isr_no_err_stub 16
isr_err_stub    17
isr_no_err_stub 18
isr_no_err_stub 19
isr_no_err_stub 20
isr_no_err_stub 21
isr_no_err_stub 22
isr_no_err_stub 23
isr_no_err_stub 24
isr_no_err_stub 25
isr_no_err_stub 26
isr_no_err_stub 27
isr_no_err_stub 28
isr_no_err_stub 29
isr_err_stub    30
isr_no_err_stub 31
_irq_stub 0
_irq_stub 1
_irq_stub 2
_irq_stub 3
_irq_stub 4
_irq_stub 5
_irq_stub 6
_irq_stub 7
_irq_stub 8
_irq_stub 9
_irq_stub 10
_irq_stub 11
_irq_stub 12
_irq_stub 13
_irq_stub 14
_irq_stub 15

isr_stub_table:
%assign i 0
%rep 32
    dd KDATA(isr_stub_%+i)
%assign i i+1
%endrep

irq_stub_table:
%assign i 0
%rep 16
    dd KDATA(irq_stub_%+i)
%assign i i+1
%endrep

%endif
