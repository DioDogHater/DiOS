kernel_start equ $
kernel_entry:
	jmp kernel_main

%define KDATA(x) ((x) - kernel_start) + 0x1000

%include "kernel/drivers/screen.nasm"
%include "kernel/interrupts/isr.nasm"

kernel_main:
	call clear_screen
	call isr_setup

	mov BYTE [KDATA(video_attribute)], WHITE_ON_BLACK
	mov edi, KDATA(test_string)
	call kprint_str

	ret

test_string:
	db "Welcome to DiOS!",10,"This is a very simple OS written in x86 assembly.",10,"This is a work in progress...",10,"Please close this VM.",10
	db 0

db 0
