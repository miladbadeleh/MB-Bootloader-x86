; Simple x86 Bootloader
; Compile with: nasm -f bin boot.asm -o boot.bin

[BITS 16]           ; 16-bit real mode
[ORG 0x7C00]        ; BIOS loads bootloader at this address

; Main entry point
start:
    ; Set up segment registers
    xor ax, ax      ; AX = 0
    mov ds, ax      ; Data Segment = 0
    mov es, ax      ; Extra Segment = 0
    mov ss, ax      ; Stack Segment = 0
    mov sp, 0x7C00  ; Stack Pointer grows downward from 0x7C00

    ; Clear screen
    mov ah, 0x06    ; Scroll up function
    xor al, al      ; Clear entire screen
    xor cx, cx      ; Upper left corner CH=row, CL=column
    mov dx, 0x184F  ; Lower right corner DH=row, DL=column
    mov bh, 0x07    ; Attribute (light gray on black)
    int 0x10

    ; Set cursor position
    mov ah, 0x02    ; Set cursor position
    xor bh, bh      ; Page 0
    mov dx, 0x0000  ; DH=row, DL=column (0,0)
    int 0x10

    ; Print boot message
    mov si, boot_msg
    call print_string

    ; Hang forever
    jmp $

; Print string function
; Input: SI = pointer to null-terminated string
print_string:
    pusha           ; Save all registers
    mov ah, 0x0E    ; BIOS teletype function

.print_char:
    lodsb           ; Load next byte from SI into AL
    or al, al       ; Check for null terminator
    jz .done        ; If null, we're done
    int 0x10        ; Otherwise, print character
    jmp .print_char ; Repeat for next character

.done:
    popa            ; Restore all registers
    ret

; Data section
boot_msg db 'Simple Bootloader - System Ready', 0x0D, 0x0A, 0x0D, 0x0A, 0

; Boot signature
times 510-($-$$) db 0   ; Pad with zeros to 510 bytes
dw 0xAA55               ; Boot signature at 511-512