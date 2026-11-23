.PHONY: all clean build run

all:
	$(MAKE) clean
	$(MAKE) build
	$(MAKE) run

clean:
	rm -rf build

build:
	mkdir -p build/boot build/kernel

	nasm -f bin boot/boot.asm -o build/boot/boot.bin
	nasm -f elf32 kernel/entry.asm -o build/kernel/entry.o
	gcc -c -m32 -ffreestanding -nostdlib -fno-pie -Wall -Wextra kernel/kernel.c -o build/kernel/kernel.o
	ld -T kernel/linker.ld -m elf_i386 build/kernel/entry.o build/kernel/kernel.o -o build/kernel/kernel.bin

	truncate -s 100000 build/disk.img
	dd if=build/boot/boot.bin of=build/disk.img conv=notrunc
	dd if=build/kernel/kernel.bin of=build/disk.img conv=notrunc bs=512 seek=1

run:
	qemu-system-x86_64 -hda build/disk.img