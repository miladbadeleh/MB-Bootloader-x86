# MB OS - A Custom x86 Bootloader and Kernel

This project implements a complete bootloader and kernel system for x86 architecture, featuring:
- FAT12 filesystem support
- Memory detection
- Protected mode switching
- Hardware initialization
- Basic kernel functionality

## Project Structure
myos/
├── stage1.asm # Stage 1 bootloader (FAT12 compatible)
├── stage2.asm # Stage 2 bootloader (protected mode switch)
├── kernel.asm # 32-bit protected mode kernel
├── includes/
│ ├── disk.inc # Disk I/O utilities
│ ├── print.inc # Printing functions
│ ├── memory.inc # Memory detection
│ └── isr.inc # Interrupt handling
├── disk.img # Generated disk image
└── README.md # This file


## Features

### Bootloader Features
- **Dual-stage architecture**:
  - Stage 1: Loads stage 2 from FAT12 filesystem
  - Stage 2: Prepares protected mode environment
- **Filesystem Support**:
  - FAT12 filesystem navigation
  - File search and loading
- **Memory Detection**:
  - Uses BIOS INT 0x15 E820 for memory map
  - Falls back to older methods if needed
- **Protected Mode Switching**:
  - A20 gate enabling
  - GDT setup
  - Unreal mode for high memory access

### Kernel Features
- **Basic Hardware Initialization**:
  - PIC remapping
  - PIT configuration
  - Keyboard controller setup
- **CPU Detection**:
  - Vendor string identification
  - Feature detection (CPUID)
- **Basic I/O**:
  - Text mode screen handling
  - String printing
- **Interrupt Handling**:
  - IDT setup
  - Default interrupt handlers

## Building and Running

### Requirements
- NASM (Netwide Assembler)
- mkfs.fat (dosfstools package)
- QEMU (for emulation)

### Build Instructions

1. Assemble all components:
   ```bash
   nasm -f bin stage1.asm -o stage1.bin
   nasm -f bin stage2.asm -o STAGE2.BIN
   nasm -f bin kernel.asm -o KERNEL.BIN
2. Create disk image:
   ```bash
dd if=/dev/zero of=disk.img bs=512 count=2880
mkfs.fat -F12 disk.img
mcopy -i disk.img STAGE2.BIN ::
mcopy -i disk.img KERNEL.BIN ::
dd if=stage1.bin of=disk.img conv=notrunc

3. Run with QEMU:
   ```bash
qemu-system-x86_64 -fda disk.img -m 64M
