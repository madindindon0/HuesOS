extern unsigned char __bss_start[], __bss_end[];

void clear_bss(void) {
    for (unsigned char* ptr = __bss_start; ptr < __bss_end; ptr++)
        *ptr = 0;
}

void kmain(void) {
    clear_bss();

    volatile unsigned char* vga_buffer = (volatile unsigned char*) 0xb8000;

    char* msg_welcome = "Welcome to HuesOS!";

    for (int i = 0; msg_welcome[i] != '\0'; i++) {
        vga_buffer[i * 2] = msg_welcome[i];
        vga_buffer[i * 2 + 1] = 0x0f; 
    }

    while (1);
}