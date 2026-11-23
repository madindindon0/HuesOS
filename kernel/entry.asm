bits 32
global entry
extern kmain

entry:
    call kmain
    jmp $