bits 16

section _TEXT class=CODE

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
    ; WARNING: bytes are converted to words (you can't push a single byte on the stack)
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
