; Enhanced Disk Utilities

; Convert cluster to LBA
cluster_to_lba:
    sub ax, 2
    xor ch, ch
    mov cl, [bpb_sects_per_clust]
    mul cx
    add ax, 33
    ret

; Read sectors using best available method
; AX = LBA, CX = sectors, ES:BX = buffer
read_sectors:
    pusha
    cmp byte [extensions_present], 1
    je .use_extensions

    ; CHS fallback
    mov [lba_sector], ax
    mov [lba_count], cx
    mov [lba_offset], bx

.chs_loop:
    ; Convert LBA to CHS
    mov ax, [lba_sector]
    xor dx, dx
    div word [bpb_sects_per_track]
    inc dl
    mov cl, dl                  ; Sector
    xor dx, dx
    div word [bpb_num_heads]
    mov dh, dl                  ; Head
    mov ch, al                  ; Cylinder

    ; BIOS read sector
    mov ah, 0x02
    mov al, 1                   ; Read one sector
    mov dl, [bpb_drive_num]
    mov bx, [lba_offset]
    int 0x13
    jc .error

    ; Update for next sector
    inc word [lba_sector]
    mov ax, [bpb_bytes_per_sect]
    add [lba_offset], ax
    dec word [lba_count]
    jnz .chs_loop
    jmp .done

.use_extensions:
    ; Extended read
    push es
    mov [dap_lba], eax
    mov [dap_segments], cx
    mov [dap_offset], bx
    mov word [dap_size], 0x10
    mov ax, es
    mov word [dap_segment], ax

    mov ah, 0x42
    mov dl, [bpb_drive_num]
    mov si, dapacket
    int 0x13
    pop es
    jc .error

.done:
    popa
    clc
    ret

.error:
    popa
    stc
    ret

; Disk Address Packet
dapacket:
dap_size:      db 0x10
               db 0
dap_segments:  dw 0
dap_offset:    dw 0
dap_segment:   dw 0
dap_lba:       dq 0

; Data
lba_sector dw 0
lba_count  dw 0
lba_offset dw 0