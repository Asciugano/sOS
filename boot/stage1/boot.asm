BITS 16
ORG 0x7C00

start:
    xor ax, ax
    mov ds, ax

    mov si, message

.print:
    lodsb
    test al, al
    jz .halt

    mov ah, 0x0E
    int 0x10
    jmp .print

.halt:
    cli
.loop:
    hlt
    jmp .loop

message db "sOS: boot sector avviato!", 0

times 510 - ($ - $$) db 0
dw 0xAA55
