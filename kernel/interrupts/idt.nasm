%ifndef IDT_TABLE_ASM
%define IDT_TABLE_ASM

; interrupt gate handler
idt_gate_t.low_offset equ 0
idt_gate_t.sel equ 2
idt_gate_t.always0 equ 4
idt_gate_t.flags equ 5
idt_gate_t.high_offset equ 6

; array of idt_gate_t
; equivalent of idt_gate_t idt[IDT_ENTRIES]
IDT_ENTRIES equ 256
idt:
    resq IDT_ENTRIES

; idt register
idt_reg:
    dw IDT_ENTRIES * 8 - 1
    dd KDATA(idt)

; edi - index
; eax - handler
set_idt_gate:
    push edi
    shl edi, 3 ; index * 8 bytes
    add edi, KDATA(idt)
    mov WORD [edi+idt_gate_t.low_offset], ax
    mov WORD [edi+idt_gate_t.sel], CODE_SEG
    mov BYTE [edi+idt_gate_t.always0], 0x00
    mov BYTE [edi+idt_gate_t.flags], 0x8E
    ror eax, 16
    mov WORD [edi+idt_gate_t.high_offset], ax
    pop edi
    ret

set_idt:
    lidt [KDATA(idt_reg)]
    sti
    ret

%endif
