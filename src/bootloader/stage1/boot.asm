org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A


; INFO:
; FAT12 header

jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; INFO: 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; INFO: 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; INFO: F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; INFO: 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; INFO: 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; INFO: reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; INFO: serial number, value doesn't matter
ebr_volume_label:           db 'S        OS'        ; INFO: 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; INFO: 8 bytes

start:
    ; INFO: setup data segments
    mov ax, 0           ; WARN: can't set ds/es directly
    mov ds, ax
    mov es, ax

    ; INFO: setup stack
    mov ss, ax
    mov sp, 0x7C00              ; WARN: stack grows downwards from where we are loaded in memory

    ; WARN: some BIOSes might start us at 07C0:0000 instead of 0000:7C00, make sure we are in the
    ; expected location
    push es
    push word .after
    retf

.after:

    ; INFO: read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    ; INFO: show loading message
    mov si, msg_loading
    call puts

    ; INFO: read drive parameters (sectors per track and head count),
    ; instead of relying on data on formatted disk
    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3F                        ; INFO: remove top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx     ; INFO: sector count

    inc dh
    mov [bdb_heads], dh                 ; INFO: head count

    ; INFO: compute LBA of root directory = reserved + fats * sectors_per_fat
    ; WARN: this section can be hardcoded
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                              ; INFO: ax = (fats * sectors_per_fat)
    add ax, [bdb_reserved_sectors]      ; INFO: ax = LBA of root directory
    push ax

    ; INFO: compute size of root directory = (32 * number_of_entries) / bytes_per_sector
    mov ax, [bdb_dir_entries_count]
    shl ax, 5                           ; INFO: ax *= 32
    xor dx, dx                          ; INFO: dx = 0
    div word [bdb_bytes_per_sector]     ; INFO: number of sectors we need to read

    test dx, dx                         ; INFO: if dx != 0, add 1
    jz .root_dir_after
    inc ax                              ; INFO: division remainder != 0, add 1
                                        ; INFO: this means we have a sector only partially filled with entries
.root_dir_after:

    ; INFO: read root directory
    mov cl, al                          ; INFO: cl = number of sectors to read = size of root directory
    pop ax                              ; INFO: ax = LBA of root directory
    mov dl, [ebr_drive_number]          ; INFO: dl = drive number (we saved it previously)
    mov bx, buffer                      ; INFO: es:bx = buffer
    call disk_read

    ; INFO: search for stage2.bin
    xor bx, bx
    mov di, buffer

.search_stage2:
    mov si, file_stage2_bin
    mov cx, 11                          ; INFO: compare up to 11 characters
    push di
    repe cmpsb
    pop di
    je .found_stage2

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_stage2

    ; ISSUE: stage2 not found
    jmp stage2_not_found_error

.found_stage2:

    ; INFO: di should have the address to the entry
    mov ax, [di + 26]                   ; INFO: first logical cluster field (offset 26)
    mov [stage2_cluster], ax

    ; INFO: load FAT from disk into memory
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; INFO: read stage2 and process FAT chain
    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    ; INFO: Read next cluster
    mov ax, [stage2_cluster]
    
    ; ISSUE: hardcoded value
    add ax, 31                          ; INFO: first cluster = (stage2_cluster - 2) * sectors_per_cluster + start_sector
                                        ; INFO: start sector = reserved + fats + root directory size = 1 + 18 + 134 = 33
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    ; INFO: compute location of next cluster
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                              ; INFO: ax = index of entry in FAT, dx = cluster mod 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; INFO: read entry from FAT table at index ax

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                      ; INFO: end of chain
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    ; INFO: jump to our stage2
    mov dl, [ebr_drive_number]          ; INFO: boot device in dl

    mov ax, STAGE2_LOAD_SEGMENT         ; INFO: set segment registers
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot             ; ISSUE: should never happen

    cli                                 ; INFO: disable interrupts, this way CPU can't get out of "halt" state
    hlt


; INFO:
; Error handlers

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

stage2_not_found_error:
    mov si, msg_stage2_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; INFO: wait for keypress
    jmp 0FFFFh:0                ; INFO: jump to beginning of BIOS, should reboot

.halt:
    cli                         ; INFO: disable interrupts, this way CPU can't get out of "halt" state
    hlt


; INFO:
; Prints a string to the screen
; Params:
;   - ds:si points to string

puts:
    ; INFO: save registers we will modify
    push si
    push ax
    push bx

.loop:
    lodsb               ; INFO: loads next character in al
    or al, al           ; INFO: verify if next character is null?
    jz .done

    mov ah, 0x0E        ; INFO: call bios interrupt
    mov bh, 0           ; INFO: set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

; INFO:
; Disk routines

; INFO:
; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head

lba_to_chs:

    push ax
    push dx

    xor dx, dx                          ; INFO: dx = 0
    div word [bdb_sectors_per_track]    ; INFO: ax = LBA / SectorsPerTrack
                                        ; INFO: dx = LBA % SectorsPerTrack

    inc dx                              ; INFO: dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          ; INFO: cx = sector

    xor dx, dx                          ; INFO: dx = 0
    div word [bdb_heads]                ; INFO: ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; INFO: dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                          ; INFO: dh = head
    mov ch, al                          ; INFO: ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; INFO: put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; INFO: restore DL
    pop ax
    ret


; INFO:
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data

disk_read:

    push ax                             ; INFO: save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; INFO: temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; INFO: compute CHS
    pop ax                              ; INFO: AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3                           ; INFO: retry count

.retry:
    pusha                               ; INFO: save all registers, we don't know what bios modifies
    stc                                 ; INFO: set carry flag, some BIOS'es don't set it
    int 13h                             ; INFO: carry flag cleared = success
    jnc .done                           ; INFO: jump if carry not set

    ; WARN: read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; WARN: all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; INFO: restore registers modified
    ret


; INFO:
; Resets disk controller
; Parameters:
;   dl: drive number

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_loading:            db 'Loading...', ENDL, 0
msg_read_failed:        db 'Read from disk failed!', ENDL, 0
msg_stage2_not_found:   db 'STAGE2.BIN file not found!', ENDL, 0
file_stage2_bin:        db 'STAGE2  BIN'
stage2_cluster:         dw 0

STAGE2_LOAD_SEGMENT     equ 0x2000
STAGE2_LOAD_OFFSET      equ 0


times 510-($-$$) db 0
dw 0AA55h

buffer:
