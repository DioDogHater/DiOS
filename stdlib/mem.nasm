%ifndef __STD_MEM_NASM
%define __STD_MEM_NASM

; eax : dest address
; edx : src address
; edi : number of bytes
memcpy:
    .loop:
    test edi, edi
    jz .end
    mov bl, BYTE [edx+edi]
    mov BYTE [eax+edi], bl
    dec edi
    jmp .loop
    .end:
    ret

; edi : dest address
; al : value
; ecx : number of bytes
memset:
    push edi
    rep stosb
    pop edi
    ret

free_mem:
    dd 0x10000

; edi : size of allocation, returned addr
; bl : align ?
kmalloc:
    push edx
    test bl, bl
    jz .no_align
    mov edx, DWORD [KDATA(free_mem)]
    and edx, 0x00000FFF
    test edx, edx
    jz .no_align

    mov edx, DWORD [KDATA(free_mem)]
    and edx, 0xFFFFF000
    add edx, 0x1000
    mov DWORD [KDATA(free_mem)], edx

    .no_align:
    mov edx, edi
    mov edi, DWORD [KDATA(free_mem)]
    add edx, edi
    mov DWORD [KDATA(free_mem)], edx

    pop edx
    ret


%endif
