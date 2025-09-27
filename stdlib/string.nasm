%ifndef __STD_STRING_NASM
%define __STD_STRING_NASM

; bl : char, resulting char
lowercase:
    cmp bl, 'A'
    jb .end
    cmp bl, 'Z'
    ja .end
    add bl, 'a'-'A'
    .end:
    ret

; edi : str
; converts str to lowercase
lowercase_str:
    push edi
    .loop:
    mov bl, [edi]
    test bl, bl
    jz .end
    call lowercase
    mov [edi], bl
    inc edi
    jmp .loop
    .end:
    pop edi
    ret

; bl : char, resulting char
uppercase:
    cmp bl, 'a'
    jb .end
    cmp bl, 'z'
    ja .end
    add bl, 'A'-'a'
    .end:
    ret

; edi : str
; converts str to uppercase
uppercase_str:
    push edi
    .loop:
    mov bl, [edi]
    test bl, bl
    jz .end
    call uppercase
    mov [edi], bl
    inc edi
    jmp .loop
    .end:
    pop edi
    ret

; edi : str
; edx : returned length
strlen:
    push edi
    mov edx, 0
    .loop:
    cmp BYTE [edi], 0
    jz .end
    inc edx
    inc edi
    jmp .loop
    .end:
    pop edi
    ret

; edi : str
reverse_str:
    pusha
    call strlen
    mov eax, 0
    .loop:
    cmp eax, edx
    jge .end
    mov bl, BYTE [edi]
    mov bh, BYTE [eax]
    mov BYTE [eax], bl
    mov BYTE [edi], bh
    inc eax
    dec edx
    .end:
    popa
    ret

; edi : str
; eax : limit size
; bl : char
append_str:
    push edx
    call strlen
    cmp edx, eax
    jae .end
    mov BYTE [edi+edx], bl
    inc edx
    mov BYTE [edi+edx], 0
    .end:
    pop edx
    ret

; edi : str
backspace_str:
    push edx
    call strlen
    test edx, edx
    jz .end
    dec edx
    mov BYTE [edi+edx], 0
    .end:
    pop edx
    ret

; eax : string a
; edi : string b
; bl : 1 if a > b, -1 if a < b or 0 if a == b
strcmp:
    push eax
    push edi
    .loop:
    mov bl, BYTE [eax]

    test bl, bl
    jnz .check_eq

    mov bl, 0
    pop edi
    pop eax
    ret

    .check_eq:
    cmp bl, BYTE [edi]
    jne .end

    inc eax
    inc edi

    jmp .loop

    .end:
    sub bl, BYTE [edi]

    pop edi
    pop eax
    ret

; eax : string a
; edi : string b
; bl : 1 if a > b, -1 if a < b or 0 if a == b
strcmp_lowercase:
    push eax
    push edi
    .loop:
    mov bl, BYTE [eax]

    test bl, bl
    jnz .check_eq

    mov bl, 0
    pop edi
    pop eax
    ret

    .check_eq:
    mov bl, BYTE [edi]
    call lowercase
    mov bh, bl
    mov bl, BYTE [eax]
    call lowercase
    cmp bl, bh
    jne .end

    inc eax
    inc edi

    jmp .loop

    .end:
    sub bl, BYTE [edi]

    pop edi
    pop eax
    ret

; eax : string a
; edi : string b
; bl : -256 if not equals, 0 if equals and <0 if a < b and >0 if a > b
strcmp_strict:
    push edx
    call strlen
    push edi
    push edx
    mov edi, eax
    call strlen
    pop ebx
    pop edi
    cmp edx, ebx
    je .strlen_equals
    mov bl, 0xFF
    jmp .end
    .strlen_equals:
    call strcmp
    .end:
    pop edx
    ret

%endif
