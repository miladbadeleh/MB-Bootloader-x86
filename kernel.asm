; Simple Kernel (32-bit protected mode)
[BITS 32]
[ORG 0x100000]

start:
    ; Set up video memory
    mov edi, 0xB8000
    mov esi, msg_kernel
    mov ah, 0x0F    ; White on black

.print_loop:
    lodsb
    test al, al
    jz .halt
    stosw
    jmp .print_loop

.halt:
    cli
    hlt

msg_kernel db 'Kernel loaded successfully!', 0