; INFO: boot address
; 0x7c00

org 0x7C00
bits 16

; INFO: MACRO per "\n"
%define ENDL 0x0D, 0x0A

_start: 
  jmp main

; INFO:
; stampa una stringa
; PARRAMS:
;   - ds:si *str
puts:
  ; INFO: salva i registri che verranno modificati
  push si
  push ax

.loop:
  lodsb                          ; INFO: load il prossimo carattere
  or al, al                       ; INFO: if chr == null
  jz .done

  mov ah, 0x0e
  mov bh, 0
  int 0x10                        ; INFO: interrupt (I/O)

  jmp .loop

.done:
  ;  WARN: Pop al contrario
  pop ax
  pop si
  ret

main:

  ; INFO: Setup Data Segment
  mov ax, 0                       ; WARN: non si puo' scrivere direttamente su "ds/es"
  mov ds, ax
  mov es, ax

  ; INFO: Setup stack
  mov ss, ax
  mov sp, 0x7C00                  ; WARN: stack sotto al bootloader perche' cresce al contrario

  mov si, msg_hello
  call puts

  hlt

.halt:
  jmp .halt



; INFO:
; MESSAGES
msg_hello: db 'Hello World!', ENDL, 0


; INFO: boot signature
; 2 x AA55

times 510-($-$$) db 0
dw 0xAA55
