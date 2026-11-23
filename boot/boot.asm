bits 16
org 0x7c00

; ==== DEFINITIONS ===========================================

%define RM_KERNEL_SEGMENT               0x1000
%define RM_KERNEL_ADDRESS               0x10000
%define PM_KERNEL_ADDRESS               0x100000
%define RM_STACK_ADDRESS                0x7c00
%define PM_STACK_ADDRESS                0x90000
%define KERNEL_SECTORS_COUNT            10

; ==== BOOTLOADER ENTRY ======================================

boot_entry:
    cli
    xor ax, ax
    mov es, ax
    mov ss, ax
    mov ds, ax
    mov sp, RM_STACK_ADDRESS
    sti

read_disk:          ; boot disk number saved to dl
    mov ah, 0x42
    mov si, dap
    int 0x13
    jc disk_error

fast_a20_line:
    cli
    in al, 0x92
    or al, 2
    and al, 0xfe
    out 0x92, al

switch_to_pm:
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:pm_entry

; ==== PROTECTED MODE ENTRY ==================================

bits 32
pm_entry:
    mov ax, DATA_SEG
    mov es, ax
    mov ds, ax
    mov ss, ax
    mov gs, ax
    mov fs, ax

    mov esp, PM_STACK_ADDRESS
    mov ebp, esp

    mov esi, RM_KERNEL_ADDRESS
    mov edi, PM_KERNEL_ADDRESS
    mov ecx, 0

copy_kernel:
    mov eax, [esi + ecx]
    mov [edi + ecx], eax

    inc ecx
    cmp ecx, sector_bytes
    jne copy_kernel

    jmp PM_KERNEL_ADDRESS

    jmp $

; ==== FUNCTIONS AND ERRORS ==================================

disk_error:
    mov si, msg_disk_error
    call print16
    jmp $

print16:
    lodsb
    test al, al
    je .exit

    mov ah, 0x0e
    int 0x10
    jmp print16

.exit:
    ret

; ==== GLOBAL DESCRIPTOR TABLE ===============================

gdt_null:
    dq 0

gdt_code:
    dw 0xFFFF, 0x0000
    db 0x00, 0x9A, 0xCF, 0x00

gdt_data:
    dw 0xFFFF, 0x0000
    db 0x00, 0x92, 0xCF, 0x00

gdt_descriptor:
    dw $ - gdt_null - 1
    dd gdt_null

CODE_SEG equ gdt_code - gdt_null
DATA_SEG equ gdt_data - gdt_null

; ==== DISK ADDRESS PACKATE ==================================

dap:
    db 0x10                         ; packet size
    db 0                            ; reserved
    dw KERNEL_SECTORS_COUNT         ; sectors count to read
    dw 0                            ; buffer offset
    dw RM_KERNEL_SEGMENT            ; buffer segment
    dq 1                            ; first sector

; ==== DATA DEFINITION =======================================

msg_disk_error: db "Error: unable to read disk", 13, 10, 0

sector_bytes equ 512 * KERNEL_SECTORS_COUNT

times 510 - ($ - $$) db 0
dw 0xaa55