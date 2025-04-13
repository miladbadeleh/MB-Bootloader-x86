; Memory Detection Utilities

; Detect memory using BIOS functions
detect_memory:
    ; Clear memory map
    mov di, memory_map
    mov cx, MAX_MEMORY_ENTRIES*20
    xor al, al
    rep stosb

    ; Use INT 0x15, EAX=0xE820
    xor ebx, ebx
    mov edi, memory_map
    mov dword [memory_entries], 0

.e820_loop:
    mov eax, 0xE820
    mov ecx, 20
    mov edx, 0x534D4150
    int 0x15
    jc .e820_done
    cmp eax, 0x534D4150
    jne .e820_done

    ; Valid entry
    inc dword [memory_entries]
    add edi, 20

    ; Check if we should continue
    test ebx, ebx
    jz .e820_done
    cmp dword [memory_entries], MAX_MEMORY_ENTRIES
    jb .e820_loop

.e820_done:
    ; Fallback to INT 0x15, AX=0xE801 if needed
    ; Fallback to INT 0x12 if needed
    ret

; Data
memory_entries dd 0
memory_map times MAX_MEMORY_ENTRIES*20 db 0
MAX_MEMORY_ENTRIES equ 32