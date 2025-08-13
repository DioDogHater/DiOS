[org 0x7C00]

KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 48

boot_raw:
	mov bp, 0x8000
	mov sp, bp

	mov bx, KERNEL_OFFSET
	mov dh, KERNEL_SECTORS
	call disk_load

	mov bx, .text
	call print_raw_str

	call switch_to_protected_mode

	.text:
	db "Booted up in raw mode.",0

; bx is the address of the string
print_raw_str:
	pusha
	mov ah, 0x0e
	.loop:
	mov al, [bx]
	test al, al
	jz .end
	int 0x10
	inc bx
	jmp .loop
	.end:
	popa
	ret

; dx is the value we want to print out
print_raw_hex:
	pusha
	mov ax, 0x0e30
	int 0x10
	mov al, 'x'
	int 0x10
	mov bl, 4
	.loop:
	and ax, 0xF000
	rol ax, 4
	mov ah, 0x0e
	add al, '0'
	cmp al, '9'
	jbe .print_char
	add al, 7
	.print_char:
	int 0x10
	shl dx, 4
	dec bl
	jnz .loop
	popa
	ret

; Read disk sectors
; dh : n sectors to read
; dl : disk number
; es+bx : Buffer pointer
disk_load:
	pusha
	push dx
	mov ah, 0x02
	mov al, dh
	mov cx, 0x0002
	mov dh, 0
	int 0x13
	jc .disk_error

	pop dx
	cmp al, dh
	jnz .sector_error

	popa
	ret

	.disk_error_txt:
		db "Disk read error: ",0
	.sector_error_txt:
		db "Incorrect number of sectors read!",0

	.disk_error:
	mov bx, .disk_error_txt
	call print_raw_str
	mov dh, ah
	call print_raw_hex
	jmp .error_loop

	.sector_error:
	mov bx, .sector_error_txt
	call print_raw_str

	.error_loop:
	jmp .error_loop

switch_to_protected_mode:
	cli
	lgdt [gdt_descriptor]
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax
	jmp CODE_SEG:init_protected_mode

[bits 32]

init_protected_mode:
	mov ax, DATA_SEG
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ebp, 0x90000
	mov esp, ebp

	call boot_protected_mode

boot_protected_mode:
	mov ebx, .text
	call print_protected_str

	call KERNEL_OFFSET

	; End loop
	.end_loop:
	hlt
	jmp .end_loop

	.text:
	db "Booted up in protected mode.",0

; prints out string in ebx
print_protected_str:
	pusha
	mov edx, 0xb8000
	mov ah, 0x0F
	.loop:
	mov al, [ebx]
	test al, al
	jz .end
	mov [edx], al
	add edx, 2
	inc ebx
	jmp .loop
	.end:
	popa
	ret

gdt_start:
    dd 0x0
    dd 0x0
gdt_code:
    dw 0xffff
	dw 0x0
	db 0x0
    db 10011010b
    db 11001111b
    db 0x0
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16 bit), always one less of its true size
    dd gdt_start ; address (32 bit)

; define some constants for later use
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Fill the rest of the boot sector with null bytes
times 510 - ($ - $$) db 0

; Magic boot sector number
dw 0xaa55

%include "kernel/kernel.nasm"
