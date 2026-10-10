; INFO: boot address
; 0x7c00

org 0x7C00
bits 16

; INFO: MACRO per "\n"
%define ENDL 0x0D, 0x0A

jmp short _start

; INFO: FAT12 Headers
nop

bdb_oem:                    db 'MSWIN4.1'             ; INFO: 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sector_per_cluster:     db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entry:              dw 0E0h
bdb_total_sectors:          dw 2880                   ; INFO: 2880 * 512 = 144MB
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sectors_count:    dd 0

; INFO: extended boot records
ebr_drive_number:           db 0
                            db 0                      ; WARN: Reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h     ; INFO: Serial number
ebr_volume_label:           db 'S        OS'          ; WARN: 11 bytes
ebr_system_id:              db 'FAT12   '             ; WARN: 8 bytes

_start: 
  jmp main


; INFO: LBA to CHS
; sector = (LBA  % sector per track) + 1
; head = (LBA / sector per track) % heads
; cylinder = (LBA / sector per track) / heads
;
; PARRAMS
;   - ax: LBA address
; RETURNS
;   - cx [0-5]: sector number
;   - cx [6-15]: cylinder
;   - dh: head

lba_to_chs:
  push ax
  push dx

  xor dx, dx                                          ; INFO: dx = 0
  div word [bdb_sectors_per_track]                    ; INFO: ax = LBA / sectors_per_track
                                                      ; INFO: dx = LBA % sectors_per_track

  inc dx                                              ; INFO: dx = (LBA % sectors_per_track + 1) = sector
  mov cx, dx                                          ; INFO: cx = sector

  xor dx, dx
  div word [bdb_heads]                                ; INFO: ax = (LBA / sectors_per_track) / heads = cylinder
                                                      ; INFO: dx = (LBA / sectors_per_track) % heads = head

  mov dh, dl                                          ; INFO: dl = head
  mov ch, al                                          ; INFO: ch = cylinder [0-8]
  shl al, 6                                           
  or cl, ah                                           ; INFO: put higher 2 bits of cylinder in cl

  pop dx
  pop ax

  ret


; INFO:
; PARRAMS
;   - ax: LBA address
;   - cl: number of sector to read
;   - dl: drive_number
;   - es:bx: memory address to store read data

disk_read:
  push ax                                             ; INFO: save registers
  push bx
  push cx
  push dx
  push di

  push cx                                             ; INFO: temp save cl(number of sectors to read)
  call lba_to_chs
  pop ax                                              ; INFO: al = number of sectors to read

  mov ah, 02h
  mov di, 3                                           ; INFO: retry count

.retry:
  pusha                                               ; INFO: save all register
  stc                                                 ; INFO: set carry flag
                                                      ; INFO: carry flag cleared = success
  int 13h
  jnc .success                                           ; INFO: jump if carry not set

  ; WARN: read failed
  popa

  call disk_reset
  jnz .retry

.fail:
  jmp floppy_error

.success:
  popa

  pop di                                              ; INFO: restore registers
  pop dx
  pop cx
  pop bx
  pop ax

  ret

; INFO:
; PARAMS
;   dl: drive_number
disk_reset:
  pusha
  mov ah, 0
  stc
  int 13h
  jc floppy_error

  popa
  ret

; INFO:
; stampa una stringa
; PARRAMS:
;   - ds:si *str
puts:
  ; INFO: salva i registri che verranno modificati
  push si
  push ax
  push bx

.loop:
  lodsb                                                 ; INFO: load il prossimo carattere
  or al, al                                             ; INFO: if chr == null
  jz .done

  mov ah, 0x0e
  mov bh, 0
  int 0x10                                              ; INFO: interrupt (I/O)

  jmp .loop

.done:
  ;  WARN: Pop al contrario
  pop ax
  pop si
  pop bx
  ret

main:
  ; INFO: Setup Data Segment
  mov ax, 0                                             ; WARN: non si puo' scrivere direttamente su "ds/es"
  mov ds, ax
  mov es, ax

  ; INFO: Setup stack
  mov ss, ax
  mov sp, 0x7C00                                        ; WARN: stack sotto al bootloader perche' cresce al contrario

  cld
  sti

  ; INFO: read something from disk
  mov [ebr_drive_number], dl

  mov ax, 1                                             ; INFO:LBA = 1 (second sector from disk)
  mov cl, 1                                             ; INFO: 1 sector to read
  mov bx, 0x7E00                                        ; INFO: data should be after bootloader
  call disk_read

  mov si, msg_read_success
  call puts

  mov si, msg_hello
  call puts

  cli
  hlt

.halt:
  cli                                                   ; INFO: disable interrupts
  hlt
  jmp .halt

floppy_error:
  mov si, msg_read_failed
  call puts

  jmp wait_key_and_reboot

wait_key_and_reboot:
  mov ah, 0
  int 16h                                               ; INFO: wait for keypress

  jmp 0xFFFF:0                                          ; INFO: jump begining of BIOS (reboot)

; INFO:
; MESSAGES
msg_hello:           db 'Hello World!', ENDL, 0
msg_read_failed:     db 'Read from disk failed!', ENDL, 0
msg_read_success:    db 'Read succeded!', ENDL, 0


; INFO: boot signature
; 2 x AA55

times 510-($-$$) db 0
dw 0xAA55
