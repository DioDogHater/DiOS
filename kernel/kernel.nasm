kernel_start equ $
kernel_entry:
	jmp kernel_main

%define KDATA(x) ((x) - kernel_start) + 0x1000

%include "kernel/drivers/screen.nasm"
%include "kernel/cpu/isr.nasm"
%include "kernel/cpu/timer.nasm"
%include "kernel/drivers/keyboard.nasm"

%include "stdlib/lib.nasm"

TIMER_RESOLUTION equ 1000

kernel_main:
	call clear_screen
	call isr_setup

	sti

	mov ebx, TIMER_RESOLUTION
	call init_timer

	call init_keyboard

	mov ax, 0
	set_video_attribute(LIGHT_BLUE_FG | BLACK_BG)
	mov edi, KDATA(.welcome_string)
	call kprint_str_offset

	set_video_default
	mov edi, KDATA(.shell_intro)
	call kprint_str_offset
	push edi
	set_video_attribute(LIGHT_ORANGE_FG | BLACK_BG)
	mov edi, KDATA(help_txt)
	call kprint_str_offset
	set_video_default
	pop edi
	inc edi
	call kprint_str_offset

	call kernel_input

	; End loop
	.end_loop:
	hlt
	jmp .end_loop

	ret

	.welcome_string:
	db "Welcome to DiOS!",10
	db "This is a very basic OS written in x86 assembly.",10,0
	.shell_intro:
	db "---- SHELL ----",10
	db "Enter ",0
	db " for commands.",10,0

help_txt:
db "help",0

help_cmd_txt:
db 10,"COMMANDS:",10,0
db "help",0," : displays this menu",0
db "clear",0," : clears the screen",0
db "time",0," : displays current time",0
db "echo <text>",0," : repeats text",0
db "END",0," : stops the CPU",10,0
db 255

input_cursor:
    dw 0

; Update the input
kernel_update:
	pusha
	mov ax, WORD [KDATA(input_cursor)]
	mov edi, KDATA(keybuffer)
	call strlen
	test edx, edx
	jnz .not_empty
	mov bx, ax
	call set_cursor_offset
	jmp .end
	.not_empty:
	call kprint_str_offset
	.end:
	popa
	ret

kernel_input:
	pushad

	; Print out the newline character
	mov bl, 10
	call kputchar

	; Test if keybuffer is empty
	mov edi, KDATA(keybuffer)
	call strlen
	test edx, edx
	jz .end

	; Check for the "help" command
	mov eax, KDATA(help_txt)
	call strcmp_lowercase
	test bl, bl
	jnz .dont_help_cmd

	.help_cmd:
	set_video_attribute(LIGHT_GREEN_FG | BLACK_BG)
	mov edi, KDATA(help_cmd_txt)
	call kprint_str
	inc edi
	.help_cmd_loop:
	cmp BYTE [edi], 255
	je .end
	set_video_attribute(LIGHT_ORANGE_FG | BLACK_BG)
	call kprint_str_offset
	inc edi
	set_video_default
	call kprint_str_offset
	inc edi
	mov bl, 10
	call kputchar_offset
	jmp .help_cmd_loop
	.dont_help_cmd:

	; Check for "clear" command
	mov eax, KDATA(.clear_txt)
	call strcmp_lowercase
	test bl, bl
	jnz .dont_clear_cmd

	.clear_cmd:
	call clear_screen
	jmp .end
	.dont_clear_cmd:

	; Check for "time" command
	mov eax, KDATA(.time_txt)
	call strcmp_lowercase
	test bl, bl
	jnz .dont_time_cmd

	.time_cmd:
	mov eax, DWORD [KDATA(time_tick)]
	xor edx, edx
	mov ebx, TIMER_RESOLUTION
	div ebx
	mov ecx, edx
	mov edx, eax
	call kprint_dec
	mov edi, KDATA(.time_fmt_s)
	call kprint_str_offset
	mov edx, ecx
	call kprint_dec_offset
	mov edi, KDATA(.time_fmt_ms)
	call kprint_str_offset
	jmp .end
	.time_fmt_ms:
	db "ms since startup.",10,0
	.time_fmt_s:
	db "s, ",0
	.dont_time_cmd:

	; Check for "echo" command
	mov eax, KDATA(.echo_txt)
	call strcmp_lowercase
	test bl, bl
	jnz .dont_echo_cmd

	.echo_cmd:
	call strlen
	cmp edx, (.echo_txt_end-.echo_txt)
	jle .not_enough_args
	set_video_attribute(LIGHT_TURQUOISE_FG | BLACK_BG)
	mov edi, KDATA(keybuffer)+(.echo_txt_end-.echo_txt)
	call kprint_str
	mov bl, 10
	call kputchar_offset
	jmp .end
	.dont_echo_cmd:

	; Check for "end" command
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

	; In case the command is unknown
	; Print out the command with err msg
	.unknown_cmd:
	set_video_error
	mov edi, KDATA(.unknown_cmd_txt)
	call kprint_str
	set_video_default
	mov edi, KDATA(keybuffer)
	call kprint_str_offset
	set_video_error
	mov bl, 34
	call kputchar_offset
	mov bl, 10
	call kputchar_offset
	jmp .end

	; Not enough args error
	.not_enough_args:
	set_video_error
	mov edi, KDATA(.not_enough_args_txt)
	call kprint_str
	jmp .end

	; Invalid args error
	.invalid_args:
	set_video_error
	mov edi, KDATA(.invalid_args_txt)
	call kprint_str


	; Print out the dollar sign to signify new command
	.end:
	set_video_attribute(LIGHT_GREEN_FG | BLACK_BG)
	mov edi, KDATA(.new_cmd_txt)
	call kprint_str
	set_video_default
	mov WORD [KDATA(input_cursor)], ax
	popad
	ret

	; the "data section"
	.new_cmd_txt:
	db "$ ",0

	.unknown_cmd_txt:
	db "Unknown command ",34,0

	.not_enough_args_txt:
	db "Not enough args.",10,0

	.invalid_args_txt:
	db "Invalid args.",10,0

	.clear_txt:
	db "clear",0

	.time_txt:
	db "time",0

	.end_txt:
	db "END",0

	.echo_txt:
	db "echo",0
	.echo_txt_end:

	.stop_cpu_txt:
	db 10,"HALTING CPU!",0
