; Stage 1 Bootloader (FAT12)
[BITS 16]
[ORG 0x7C00]

; FAT12 BIOS Parameter Block (BPB)
jmp short start
nop

; FAT12 BPB
bpb_oem:            db 'MYOS    '
bpb_bytes_per_sect: dw 512
bpb_sects_per_clust:db 1
bpb_reserved_sects: dw 1
bpb_num_fats:       db 2
bpb_root_entries:   dw 224
bpb_total_sects:    dw 2880
bpb_media:          db 0xF0
bpb_sects_per_fat:  dw 9
bpb_sects_per_track:dw 18
bpb_num_heads:      dw 2
bpb_hidden_sects:   dd 0
bpb_total_sects_big:dd 0
bpb_drive_num:      db 0
bpb_reserved:       db 0
bpb_boot_signature: db 0x29
bpb_volume_id:      dd 0x12345678
bpb_volume_label:   db 'MYOS VOLUME'
bpb_file_system:    db 'FAT12   '

start:
    ; Set up segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive
    mov [bpb_drive_num], dl

    ; Load stage 2 bootloader
    mov si, msg_loading
    call print_string

    ; Read root directory
    mov ax, 19          ; First sector of root directory
    mov cx, 14          ; Number of sectors to read
    mov bx, buffer      ; Destination buffer
    call read_sectors

    ; Search for stage2 file
    mov cx, [bpb_root_entries]
    mov di, buffer

.search_loop:
    push cx
    mov cx, 11
    mov si, stage2_name
    push di
    repe cmpsb
    pop di
    je .found_file
    pop cx
    add di, 32
    loop .search_loop

    ; File not found
    mov si, msg_stage2_not_found
    call print_string
    jmp $

.found_file:
    ; Get first cluster
    mov ax, [di + 26]   ; First cluster in directory entry
    mov [cluster], ax

    ; Read FAT
    mov ax, 1           ; First sector of FAT
    mov cx, [bpb_sects_per_fat]
    mov bx, buffer
    call read_sectors

    ; Load stage2 at 0x7E00 (right after bootloader)
    mov bx, 0x7E00
    mov es, bx
    xor bx, bx

.load_file_loop:
    ; Read cluster
    mov ax, [cluster]
    call cluster_to_lba
    mov cx, 1
    mov bx, es
    mov ds, bx
    xor bx, bx
    call read_sectors
    mov bx, ds
    mov es, bx
    mov ds, ax          ; Restore DS (AX was clobbered)

    ; Get next cluster
    mov ax, [cluster]
    mov cx, ax
    mov dx, ax
    shr dx, 1
    add ax, dx          ; AX = cluster * 1.5
    mov si, buffer
    add si, ax
    mov ax, [si]

    test cx, 1
    jnz .odd_cluster
.even_cluster:
    and ax, 0x0FFF      ; Mask for even cluster
    jmp .next_cluster
.odd_cluster:
    shr ax, 4           ; Mask for odd cluster
.next_cluster:
    cmp ax, 0x0FF8      ; End of chain?
    jae .end_of_file
    mov [cluster], ax
    mov ax, [bpb_bytes_per_sect]
    shr ax, 4           ; AX = bytes per sector / 16 (paragraphs)
    add bx, ax
    mov es, bx
    jmp .load_file_loop

.end_of_file:
    ; Jump to stage2
    mov dl, [bpb_drive_num]
    jmp 0x7E00:0000

; Includes for stage1
%include "disk.inc"
%include "print.inc"

; Data
stage2_name      db 'STAGE2  BIN'
msg_loading      db 'Loading stage2...', 0x0D, 0x0A, 0
msg_stage2_not_found db 'Stage2 not found!', 0
cluster          dw 0

; Pad and add boot signature
times 510-($-$$) db 0
dw 0xAA55