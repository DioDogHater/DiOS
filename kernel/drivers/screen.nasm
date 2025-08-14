%ifndef SCREEN_ASM
%define SCREEN_ASM

%include "kernel/drivers/ports.nasm"

; Video memory constants
MAX_COLS equ 80
MAX_ROWS equ 25
MAX_CHARS equ MAX_COLS * MAX_ROWS
VIDEO_MEMORY equ 0xB8000
VIDEO_MEMORY_SIZE equ MAX_CHARS * 2
VIDEO_MEMORY_END equ VIDEO_MEMORY + VIDEO_MEMORY_SIZE

; Colors
WHITE_ON_BLACK equ 0x0F
BLACK_FG equ 0x00
BLACK_BG equ 0x00
BLUE_FG equ 0x01
BLUE_BG equ 0x10
GREEN_FG equ 0x02
GREEN_BG equ 0x20
TURQUOISE_FG equ 0x03
TURQUOISE_BG equ 0x30
RED_FG equ 0x04
RED_BG equ 0x40
PURPLE_FG equ 0x05
PURPLE_BG equ 0x50
ORANGE_FG equ 0x06
ORANGE_BG equ 0x60
GRAY_FG equ 0x07
GRAY_BG equ 0x70
DARK_GRAY_FG equ 0x08
DARK_GRAY_BG equ 0x80
LIGHT_BLUE_FG equ 0x09
LIGHT_BLUE_BG equ 0x90
LIGHT_GREEN_FG equ 0x0A
LIGHT_GREEN_BG equ 0xA0
LIGHT_TURQUOISE_FG equ 0x0B
LIGHT_TURQUOISE_BG equ 0xB0
LIGHT_RED_FG equ 0x0C
LIGHT_RED_BG equ 0xC0
LIGHT_PURPLE_FG equ 0x0D
LIGHT_PURPLE_BG equ 0xD0
LIGHT_ORANGE_FG equ 0x0E
LIGHT_ORANGE_BG equ 0xE0
WHITE_FG equ 0x0F
WHITE_BG equ 0xF0

; Video adapter registers
REG_SCREEN_CTRL equ 0x3D4
REG_SCREEN_DATA equ 0x3D5

video_attribute:
	db WHITE_ON_BLACK

cursor_enabled:
	db 0x01

%define set_video_attribute(x) mov BYTE [KDATA(video_attribute)], (x)
%define set_video_default set_video_attribute(WHITE_ON_BLACK)

%define enable_cursor mov BYTE [KDATA(cursor_enabled)], 0x01
%define disable_cursor mov BYTE [KDATA(cursor_enabled)], 0x00

; dl - x, dh - y
; ax - result
get_screen_offset:
	mov al, dh
	mov ah, MAX_COLS
	mul ah
	push bx
	movzx bx, dl
	add ax, bx
	pop bx
	shl ax, 1
	ret

; ax - offset
; dh - result
get_screen_offset_y:
	mov dx, MAX_COLS
	shl dx, 1
	div dx
	mov al, dh
	ret

; ax - offset
; dl - result
get_screen_offset_x:
	mov dx, MAX_COLS
	shl dx, 1
	div dx
	mov ah, dl
	ret

; bx - offset
get_cursor_offset:
	portx_byte_out REG_SCREEN_CTRL, 14
	portx_byte_in REG_SCREEN_DATA
	mov bh, al
	portx_byte_out REG_SCREEN_CTRL, 15
	portx_byte_in REG_SCREEN_DATA
	mov bl, al
	shl bx, 1
	ret

; bx - offset
set_cursor_offset:
	pusha
	shr bx, 1
	portx_byte_out REG_SCREEN_CTRL, 14
	portx_byte_out REG_SCREEN_DATA, bh
	portx_byte_out REG_SCREEN_CTRL, 15
	portx_byte_out REG_SCREEN_DATA, bl
	popa
	ret

clear_screen:
	pusha
	mov eax, VIDEO_MEMORY
	mov ebx, 0
	mov dx, 0x0F00
	.loop:
	cmp ebx, MAX_CHARS
	jge .end
	mov WORD [eax], dx
	add eax, 2
	inc ebx
	jmp .loop
	.end:
	mov bx, 0
	call set_cursor_offset
	popa
	ret

scroll_screen:
	pusha
	mov eax, VIDEO_MEMORY
	mov ebx, 0
	.loop:
	cmp ebx, MAX_CHARS
	jae .end
	cmp ebx, MAX_CHARS - MAX_COLS
	jae .last_line
	.not_last_line:
	mov dx, WORD [eax + (MAX_COLS * 2)]
	jmp .set_char
	.last_line:
	mov dx, 0x0F00
	.set_char:
	mov WORD [eax], dx
	add eax, 2
	inc ebx
	jmp .loop
	.end:
	popa
	sub ax, MAX_COLS * 2
	ret

; bl - char
kputchar:
	push bx
	call get_cursor_offset
	mov ax, bx
	pop bx
	jmp kputchar_offset

; dl - x, dh - y
; bl - char
kputchar_at:
	call get_screen_offset
	jmp kputchar_offset

; ax - offset and result
; bl - char
kputchar_offset:
	cmp bl, 10
	jne .normal_char

	.newline:
	add ax, MAX_COLS * 2
	push bx
	push dx
	mov bx, MAX_COLS * 2
	xor dx, dx
	div bx
	mul bx
	pop dx
	pop bx
	jmp .update_cursor

	.normal_char:
	and eax, 0x0000FFFF
	mov bh, BYTE [KDATA(video_attribute)]
	add eax, VIDEO_MEMORY
	mov WORD [eax], bx
	sub eax, VIDEO_MEMORY - 2

	.update_cursor:
	cmp ax, VIDEO_MEMORY_SIZE
	jb .move_cusor

	.scroll:
	call scroll_screen

	.move_cusor:
	push bx
	mov bl, BYTE [KDATA(cursor_enabled)]
	test bl, bl
	jz .skip_cursor_offset
	mov bx, ax
	call set_cursor_offset
	.skip_cursor_offset:
	pop bx

	ret

kprint_hex:
	push bx
	push edx
	call get_cursor_offset
	mov ax, bx
	pop edx
	pop bx
	jmp kprint_hex_offset

; edx - value
; ax - offset
kprint_hex_offset:
	mov bl, '0'
	call kputchar_offset
	mov bl, 'x'
	call kputchar_offset
	mov di, 8
	.loop:
	mov ebx, edx
	and ebx, 0xF0000000
	rol ebx, 4
	add bl, '0'
	cmp bl, '9'
	jbe .number
	add bl, 7
	.number:
	call kputchar_offset
	rol edx, 4
	dec di
	jnz .loop
	ret

kprint_dec:
	push edx
	push bx
	call get_cursor_offset
	mov ax, bx
	pop bx
	pop edx
	jmp kprint_dec_offset

; edx - value
; ax - offset
kprint_dec_offset:
	push edx
	push ax
	cmp edx, 0
	jz .print_zero
	jge .setup
	neg edx
	.setup:
	mov edi, KDATA(.buffer)+10
	mov ebx, 10
	.loop:
	test edx, edx
	jz .end
	mov eax, edx
	xor edx, edx
	div ebx
	add dl, '0'
	mov BYTE [edi], dl
	mov edx, eax
	dec edi
	jmp .loop
	.end:
	pop ax
	pop edx
	cmp edx, 0
	jge .ignore_sign
	mov BYTE [edi], '-'
	dec edi
	.ignore_sign:
	inc edi
	jmp kprint_str_offset

	.print_zero:
	pop ax
	pop edx
	mov bl, '0'
	jmp kputchar_offset

	.buffer:
		db " 4294967295",0

; edi - string ptr
kprint_str:
	push bx
	call get_cursor_offset
	mov ax, bx
	pop bx
	jmp kprint_str_offset

; ax - offset
; edi - string ptr
kprint_str_offset:
	.loop:
	mov bl, BYTE [edi]
	test bl, bl
	jz .end
	call kputchar_offset
	inc edi
	jmp .loop
	.end:
	ret

%endif
