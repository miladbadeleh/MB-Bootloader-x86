; Stage 2 Bootloader
[BITS 16]
[ORG 0x7E00]

start:
    ; Set up segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Display message
    mov si, msg_stage2
    call print_string

    ; Load kernel
    mov si, msg_loading_kernel
    call print_string

    ; Search for kernel in root directory
    ; (Similar to stage1 search, but looking for KERNEL.BIN)
    ; For brevity, we'll assume we've loaded it at 0x100000 (1MB)

    ; Switch to protected mode
    call enable_a20
    call load_gdt
    call enter_pm

    ; We shouldn't get here
    jmp $

; Enable A20 line
enable_a20:
    cli
    call .wait_input
    mov al, 0xAD
    out 0x64, al
    call .wait_input
    mov al, 0xD0
    out 0x64, al
    call .wait_output
    in al, 0x60
    push eax
    call .wait_input
    mov al, 0xD1
    out 0x64, al
    call .wait_input
    pop eax
    or al, 2
    out 0x60, al
    call .wait_input
    mov al, 0xAE
    out 0x64, al
    call .wait_input
    sti
    ret

.wait_input:
    in al, 0x64
    test al, 2
    jnz .wait_input
    ret

.wait_output:
    in al, 0x64
    test al, 1
    jz .wait_output
    ret

; Load GDT
load_gdt:
    lgdt [gdt_descriptor]
    ret

; Enter protected mode
enter_pm:
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:init_pm

[BITS 32]
init_pm:
    ; Set up segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Call kernel
    jmp CODE_SEG:0x100000

; GDT
gdt_start:
gdt_null:
    dd 0
    dd 0

gdt_code:
    dw 0xFFFF       ; Limit (0-15)
    dw 0x0000       ; Base (0-15)
    db 0x00         ; Base (16-23)
    db 10011010b    ; Access byte
    db 11001111b    ; Flags + Limit (16-19)
    db 0x00         ; Base (24-31)

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Data
msg_stage2 db 'Stage2 bootloader running...', 0x0D, 0x0A, 0
msg_loading_kernel db 'Loading kernel...', 0x0D, 0x0A, 0