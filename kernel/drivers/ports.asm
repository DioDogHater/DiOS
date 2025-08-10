%ifndef PORTS_ASM
%define PORTS_ASM

; dx - port number
; al - output
port_byte_in:
	in al, dx
	ret

; dx - port number
; al - input
port_byte_out:
	out dx, al
	ret

; dx - port number
; ax - output
port_word_in:
	in ax, dx
	ret

; dx - port number
; ax - input
port_word_out:
	out dx, ax
	ret

%endif