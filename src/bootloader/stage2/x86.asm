bits 16

section _TEXT class=CODE

; INFO:
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);

global _x86_div64_32
_x86_div64_32:

    ; INFO: make new call frame
    push bp             ; INFO: save old call frame
    mov bp, sp          ; INFO: initialize new call frame

    push bx

    ; INFO: divide upper 32 bits
    mov eax, [bp + 8]   ; INFO: eax <- upper 32 bits of dividend
    mov ecx, [bp + 12]  ; INFO: ecx <- divisor
    xor edx, edx
    div ecx             ; INFO: eax - quot, edx - remainder

    ; INFO: store upper 32 bits of quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; INFO: divide lower 32 bits
    mov eax, [bp + 4]   ; INFO: eax <- lower 32 bits of dividend
                        ; INFO: edx <- old remainder
    div ecx

    ; INFO: store results
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx

    ; INFO: restore old call frame
    mov sp, bp
    pop bp
    ret

; INFO:
; int 10h ah=0Eh
; args: character, page

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    
    ; INFO: make new call frame
    push bp             ; INFO: save old call frame
    mov bp, sp          ; INFO: initialize new call frame

    ; INFO: save bx
    push bx

    ; INFO: [bp + 0] - old call frame
    ; INFO: [bp + 2] - return address (small memory model => 2 bytes)
    ; INFO: [bp + 4] - first argument (character)
    ; INFO: [bp + 6] - second argument (page)
    ; WARN: bytes are converted to words (you can't push a single byte on the stack)
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    ; INFO: restore bx
    pop bx

    ; INFO: restore old call frame
    mov sp, bp
    pop bp
    ret
