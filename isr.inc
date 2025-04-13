; Interrupt Service Routines

; Set up IDT
init_idt:
    ; Create IDT entries
    mov ecx, 256
    mov edi, idt
    mov eax, default_isr

.setup_entry:
    mov word [edi], ax          ; Low 16 bits of ISR
    mov word [edi + 2], 0x08    ; Code segment selector
    mov word [edi + 4], 0x8E00  ; Present, DPL=0, 32-bit interrupt gate
    shr eax, 16
    mov word [edi + 6], ax      ; High 16 bits of ISR
    add edi, 8
    add eax, (default_isr_1 - default_isr)
    loop .setup_entry

    ; Load IDT
    lidt [idt_descriptor]
    ret

; Default ISR
default_isr:
    pusha
    mov esi, msg_isr
    call print_string
    popa
    iretd

default_isr_1:
    iret

; IDT
idt:
    times 256 dq 0

idt_descriptor:
    dw 256 * 8 - 1
    dd idt

; Data
msg_isr db 'Unhandled interrupt!', 0x0A, 0