kernel_start equ $
kernel_entry:
	jmp kernel_main

%define KDATA(x) ((x) - kernel_start) + 0x1000

%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/isr.nasm"
%include "kernel/cpu/timer.nasm"
%include "kernel/drivers/keyboard.nasm"

kernel_main:
	call clear_screen
	call isr_setup

	sti

	xor ebx, 50
	call init_timer

	call init_keyboard

	mov ax, 0
	mov edi, KDATA(welcome_string)
	call kprint_str_offset

	set_video_attribute(BLUE_FG | BLACK_BG)
	mov dl, 0
	mov dh, 4
	mov bl, '$'
	call kputchar_at
	set_video_default
	add ax, 2
	mov bx, ax
	call set_cursor_offset

	ret

welcome_string:
	db "Welcome to DiOS!",10,"This is a very simple OS written in x86 assembly.",10,"This is a work in progress...",10,10,0

db 0
