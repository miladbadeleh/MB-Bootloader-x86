; Enhanced Kernel
[BITS 32]
[ORG 0x100000]

; Kernel entry point
start:
    ; Set up stack
    mov esp, 0x90000

    ; Clear screen
    call clear_screen

    ; Print welcome message
    mov esi, msg_welcome
    call print_string

    ; Detect CPU features
    call detect_cpu

    ; Initialize hardware
    call init_pic
    call init_pit
    call init_keyboard

    ; Enable interrupts
    sti

    ; Main kernel loop
.main_loop:
    hlt
    jmp .main_loop

; Hardware Initialization
init_pic:
    ; Remap PIC IRQs
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    mov al, 0x20    ; IRQ 0-7 -> INT 0x20-0x27
    out 0x21, al
    mov al, 0x28    ; IRQ 8-15 -> INT 0x28-0x2F
    out 0xA1, al

    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; Mask all interrupts except keyboard
    mov al, 0xFD
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al
    ret

init_pit:
    ; Configure PIT for 100Hz
    mov al, 0x36
    out 0x43, al
    mov ax, 1193180 / 100
    out 0x40, al
    mov al, ah
    out 0x40, al
    ret

init_keyboard:
    ; Enable keyboard interrupts
    in al, 0x21
    and al, 0xFD
    out 0x21, al
    ret

; CPU Detection
detect_cpu:
    ; Check for CPUID
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 0x200000
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    jz .no_cpuid

    ; Get vendor string
    xor eax, eax
    cpuid
    mov [cpu_vendor], ebx
    mov [cpu_vendor+4], edx
    mov [cpu_vendor+8], ecx
    mov byte [cpu_vendor+12], 0

    ; Print vendor string
    mov esi, msg_cpu_vendor
    call print_string
    mov esi, cpu_vendor
    call print_string
    mov esi, newline
    call print_string

    ; Get features
    mov eax, 1
    cpuid
    test edx, 1 << 4  ; Test TSC
    jz .no_tsc
    mov byte [cpu_has_tsc], 1

.no_tsc:
.no_cpuid:
    ret

; Screen Functions
clear_screen:
    mov edi, 0xB8000
    mov ecx, 80*25
    mov ah, 0x0F    ; White on black
    mov al, ' '
    rep stosw
    mov dword [cursor_pos], 0
    ret

print_string:
    mov edi, [cursor_pos]
    shl edi, 1
    add edi, 0xB8000

.loop:
    lodsb
    test al, al
    jz .done
    cmp al, 0x0A    ; Newline
    je .newline
    stosb
    inc edi
    inc dword [cursor_pos]
    jmp .loop

.newline:
    mov eax, [cursor_pos]
    mov ecx, 80
    xor edx, edx
    div ecx
    inc eax
    mul ecx
    mov [cursor_pos], eax
    jmp .loop

.done:
    ret

; Data
msg_welcome db 'MyOS Kernel v1.0', 0x0A, 0
msg_cpu_vendor db 'CPU: ', 0
newline db 0x0A, 0
cpu_vendor times 13 db 0
cpu_has_tsc db 0
cursor_pos dd 0

; Interrupt Service Routines
%include "isr.inc"