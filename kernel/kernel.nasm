kernel_start equ $
kernel_entry:
	jmp kernel_main

%define KDATA(x) ((x) - kernel_start) + 0x1000

%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/isr.nasm"
%include "kernel/cpu/timer.nasm"
%include "kernel/drivers/keyboard.nasm"

%include "stdlib/lib.nasm"

kernel_main:
	call clear_screen
	call isr_setup

	sti

	mov ebx, 50
	call init_timer

	call init_keyboard

	mov ax, 0
	mov edi, KDATA(.welcome_string)
	call kprint_str_offset

	call kernel_input

	; End loop
	.end_loop:
	hlt
	jmp .end_loop

	ret

	.welcome_string:
	db "Welcome to DiOS!",10,"This is a very simple OS written in x86 assembly.",10,"This is a work in progress...",10,0

kernel_input:
	pusha
	mov bl, 10
	call kputchar

	mov edi, KDATA(keybuffer)
	call strlen
	test edx, edx
	jz .end

	mov eax, KDATA(.end_txt)
	call strcmp_strict
	test bl, bl
	jnz .dont_stop_cpu

	.stop_cpu:
	set_video_error
	mov edi, KDATA(.stop_cpu_txt)
	call kprint_str
	cli
	hlt
	.dont_stop_cpu:

	mov eax, KDATA(.echo_txt)
	call strcmp_lowercase
	test bl, bl
	jnz .dont_echo_cmd

	.echo_cmd:
	cmp edx, (.echo_txt_end-.echo_txt)
	ja .enough_echo_args
	set_video_error
	mov edi, KDATA(.not_enough_args)
	call kprint_str
	jmp .end
	.enough_echo_args:
	set_video_attribute(LIGHT_BLUE_FG | BLACK_BG)
	mov edi, KDATA(keybuffer)+(.echo_txt_end-.echo_txt)
	call kprint_str
	jmp .end
	.dont_echo_cmd:

	set_video_error
	mov edi, KDATA(.unknown_cmd_txt)
	call kprint_str
	set_video_default
	mov edi, KDATA(keybuffer)
	call kprint_str_offset
	set_video_error
	mov bl, 34
	call kputchar_offset

	.end:
	set_video_attribute(LIGHT_GREEN_FG | BLACK_BG)
	mov edi, KDATA(.new_cmd_txt)
	call kprint_str
	set_video_default
	popa
	ret

	; the "data section"
	.new_cmd_txt:
	db 10,"$ ",0

	.unknown_cmd_txt:
	db "Unknown command ",34,0

	.not_enough_args:
	db "Not enough args.",0

	.end_txt:
	db "END",0
	.echo_txt:

	db "echo",0
	.echo_txt_end:

	.stop_cpu_txt:
	db 10,"HALTING CPU!",0

db 0
