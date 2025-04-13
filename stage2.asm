; Enhanced Stage 2 Bootloader
[BITS 16]
[ORG 0x7E00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive
    mov [boot_drive], dl

    ; Detect memory
    call detect_memory
    mov si, msg_memory_detected
    call print_string

    ; Load kernel
    mov si, msg_loading_kernel
    call print_string

    ; Search for kernel in root directory
    mov ax, 19
    mov cx, 14
    mov bx, buffer
    call read_sectors
    jc disk_error

    mov cx, [bpb_root_entries]
    mov di, buffer

.search_loop:
    push cx
    mov cx, 11
    mov si, kernel_name
    push di
    repe cmpsb
    pop di
    je .found_kernel
    pop cx
    add di, 32
    loop .search_loop

    ; Kernel not found
    mov si, msg_kernel_not_found
    call print_string
    jmp $

.found_kernel:
    ; Get first cluster
    mov ax, [di + 26]
    mov [cluster], ax

    ; Read FAT
    mov ax, 1
    mov cx, [bpb_sects_per_fat]
    mov bx, buffer
    call read_sectors
    jc disk_error

    ; Load kernel at 1MB (0x100000)
    ; We need to use unreal mode to access high memory
    call enable_unreal_mode

    mov edi, 0x100000
    mov bx, 0x1000
    mov es, bx

.load_kernel_loop:
    ; Read cluster
    mov ax, [cluster]
    call cluster_to_lba
    mov cx, 1
    xor bx, bx
    call read_sectors
    jc disk_error

    ; Copy to high memory
    mov esi, buffer
    mov ecx, 512/4
    rep movsd

    ; Get next cluster
    mov ax, [cluster]
    mov cx, ax
    mov dx, ax
    shr dx, 1
    add ax, dx
    mov si, buffer
    add si, ax
    mov ax, [si]

    test cx, 1
    jnz .odd_cluster
.even_cluster:
    and ax, 0x0FFF
    jmp .next_cluster
.odd_cluster:
    shr ax, 4
.next_cluster:
    cmp ax, 0x0FF8
    jae .end_of_file
    mov [cluster], ax
    jmp .load_kernel_loop

.end_of_file:
    ; Switch to protected mode
    call enable_a20
    call load_gdt
    call enter_pm

enable_unreal_mode:
    ; Enable unreal mode to access high memory
    push ds
    lgdt [unreal_gdt_descriptor]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    mov bx, 0x08
    mov ds, bx
    and al, 0xFE
    mov cr0, eax
    pop ds
    ret

enable_a20:
    ; Try different A20 methods
    call .keyboard_controller
    call .bios_function
    call .fast_a20
    ret

.keyboard_controller:
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

.bios_function:
    mov ax, 0x2401
    int 0x15
    ret

.fast_a20:
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    and al, 0xFE
    out 0x92, al
.done:
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

load_gdt:
    lgdt [gdt_descriptor]
    ret

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

    ; Copy memory map to known location
    mov esi, memory_map
    mov edi, 0x5000
    mov ecx, [memory_entries]
    shl ecx, 2           ; Each entry is 20 bytes
    rep movsb

    ; Jump to kernel
    jmp CODE_SEG:0x100000

; GDT
gdt_start:
gdt_null:
    dd 0
    dd 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

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

; Unreal mode GDT
unreal_gdt:
    dw 0, 0, 0, 0
    dw 0xFFFF
    dw 0
    dw 0x9200
    dw 0x008F

unreal_gdt_descriptor:
    dw 0x10
    dd unreal_gdt

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

%include "disk.inc"
%include "print.inc"
%include "memory.inc"

; Data
msg_memory_detected db 'Memory map created', 0x0D, 0x0A, 0
msg_loading_kernel db 'Loading kernel...', 0x0D, 0x0A, 0
msg_kernel_not_found db 'Kernel not found!', 0
boot_drive db 0
cluster dw 0
buffer times 512 db 0