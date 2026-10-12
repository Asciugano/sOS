bits 16

section _TEXT class=CODE


; INFO:
; U4D
;
; Operation:      Unsigned 4 byte divide
; Inputs:         DX;AX   Dividend
;                 CX;BX   Divisor
; Outputs:        DX;AX   Quotient
;                 CX;BX   Remainder
; Volatile:       none

global __U4D
__U4D:
  shl edx, 16         ; INFO: dx to upper half of edx
  mov dx, ax          ; INFO: edx - dividend
  mov eax, edx        ; INFO: eax - dividend
  xor edx, edx

  shl ecx, 16         ; INFO: cx to upper half of ecx
  mov cx, bx          ; INFO: ecx - divisor

  div ecx             ; INFO: eax - quot, edx - remainder
  mov ebx, edx
  mov ecx, edx
  shr ecx, 16

  mov edx, eax
  shr edx, 16

  ret


; INFO:
; U4M
; Operation:      integer four byte multiply
; Inputs:         DX;AX   integer M1
;                 CX;BX   integer M2
; Outputs:        DX;AX   product
; Volatile:       CX, BX destroyed
;
global __U4M
__U4M:
  shl edx, 16         ; INFO:  dx to upper half of edx
  mov dx, ax          ; INFO:  m1 in edx
  mov eax, edx        ; INFO:  m1 in eax

  shl ecx, 16         ; INFO: cx to upper half of ecx
  mov cx, bx          ; INFO: m2 in ecx

  mul ecx             ; INFO: result in edx:eax (we only need eax)
  mov edx, eax        ; INFO: move upper half to dx
  shr edx, 16

  ret

; INFO:
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);
;
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
;
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


; INFO:
; bool _cdecl x86_Disk_Reset(uint8_t drive);
;
global _x86_Disk_Reset
_x86_Disk_Reset:

  ; INFO: make new call frame
  push bp             ; INFO: save old call frame
  mov bp, sp          ; INFO: initialize new call frame

  mov ah, 0
  mov dl, [bp + 4]    ; INFO: dl - drive
  stc
  int 13h

  mov ax, 1
  sbb ax, 0           ; INFO: 1 on success, 0 on fail   

  ; INFO: restore old call frame
  mov sp, bp
  pop bp
  ret


; INFO:
; bool _cdecl x86_Disk_Read(uint8_t drive,
;                           uint16_t cylinder,
;                           uint16_t sector,
;                           uint16_t head,
;                           uint8_t count,
;                           void far * dataOut);
;
global _x86_Disk_Read
_x86_Disk_Read:

  ; INFO: make new call frame
  push bp             ; INFO: save old call frame
  mov bp, sp          ; INFO: initialize new call frame

  ; INFO: save modified regs
  push bx
  push es

  ; INFO: setup args
  mov dl, [bp + 4]    ; INFO: dl - drive

  mov ch, [bp + 6]    ; INFO: ch - cylinder (lower 8 bits)
  mov cl, [bp + 7]    ; INFO: cl - cylinder to bits 6-7
  shl cl, 6
  
  mov al, [bp + 8]    ; INFO: cl - sector to bits 0-5
  and al, 3Fh
  or cl, al

  mov dh, [bp + 10]   ; INFO: dh - head

  mov al, [bp + 12]   ; INFO: al - count

  mov bx, [bp + 16]   ; INFO: es:bx - far pointer to data out
  mov es, bx
  mov bx, [bp + 14]

  ; INFO: call int13h
  mov ah, 02h
  stc
  int 13h

  ; INFO: set return value
  mov ax, 1
  sbb ax, 0           ; INFO: 1 on success, 0 on fail   

  ; INFO: restore regs
  pop es
  pop bx

  ; INFO: restore old call frame
  mov sp, bp
  pop bp
  ret


; INFO:
; bool _cdecl x86_Disk_GetDriveParams(uint8_t drive,
;                                     uint8_t* driveTypeOut,
;                                     uint16_t* cylindersOut,
;                                     uint16_t* sectorsOut,
;                                     uint16_t* headsOut);
;
global _x86_Disk_GetDriveParams
_x86_Disk_GetDriveParams:

  ; INFO: make new call frame
  push bp             ; INFO: save old call frame
  mov bp, sp          ; INFO: initialize new call frame

  ; INFO: save regs
  push es
  push bx
  push si
  push di

  ; INFO: call int13h
  mov dl, [bp + 4]    ; INFO: dl - disk drive
  mov ah, 08h
  mov di, 0           ; INFO: es:di - 0000:0000
  mov es, di
  stc
  int 13h

  mov ax, 1
  sbb ax, 0

  ; INFO: out params
  mov si, [bp + 6]    ; INFO: drive type from bl
  mov [si], bl

  mov bl, ch          ; INFO: cylinders - lower bits in ch
  mov bh, cl          ; INFO: cylinders - upper bits in cl (6-7)
  shr bh, 6
  mov si, [bp + 8]
  mov [si], bx

  xor ch, ch          ; INFO: sectors - lower 5 bits in cl
  and cl, 3Fh
  mov si, [bp + 10]
  mov [si], cx

  mov cl, dh          ; INFO: heads - dh
  mov si, [bp + 12]
  mov [si], cx

  ; INFO: restore regs
  pop di
  pop si
  pop bx
  pop es

  ; INFO: restore old call frame
  mov sp, bp
  pop bp
  ret
