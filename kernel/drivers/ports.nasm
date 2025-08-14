%ifndef PORTS_ASM
%define PORTS_ASM

%macro port_byte_in 1
	in al, %1
%endmacro

%macro portx_byte_in 1
	mov dx, %1
	in al, dx
%endmacro

%macro port_byte_out 2
	mov al, %2
	out %1, al
%endmacro

%macro portx_byte_out 2
	mov dx, %1
	mov al, %2
	out dx, al
%endmacro

%macro port_word_in 1
	in ax, %1
%endmacro

%macro portx_word_in 1
	mov dx, %1
	in ax, dx
%endmacro

%macro port_word_out 2
	mov ax, %2
	out %1, al
%endmacro

%macro portx_word_out 2
	mov dx, %1
	mov ax, %2
	out dx, al
%endmacro

%endif
