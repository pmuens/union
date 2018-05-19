arch ?= x86_64
src := src/arch/$(arch)
dist := target

default: build

.PHONY: default build run clean

run: target/os.iso
	qemu-system-x86_64 -cdrom target/os.iso -curses

build: $(dist)/kernel.bin

cargo:
	@RUST_TARGET_PATH=$(shell pwd) xargo build --release --target x86_64-unknown-union-gnu

clean:
	cargo clean

$(dist)/multiboot_header.o: $(src)/multiboot_header.asm
	mkdir -p target
	nasm -f elf64 $(src)/multiboot_header.asm -o $(dist)/multiboot_header.o

$(dist)/boot.o: $(src)/boot.asm
	mkdir -p target
	nasm -f elf64 $(src)/boot.asm -o $(dist)/boot.o

$(dist)/kernel.bin: $(dist)/multiboot_header.o $(dist)/boot.o $(src)/linker.ld cargo
	ld -n -o $(dist)/kernel.bin -T $(src)/linker.ld $(dist)/multiboot_header.o $(dist)/boot.o $(dist)/$(arch)-unknown-union-gnu/release/libunion.a

$(dist)/os.iso: $(dist)/kernel.bin $(src)/grub.cfg
	mkdir -p $(dist)/isofiles/boot/grub
	cp $(src)/grub.cfg $(dist)/isofiles/boot/grub
	cp $(dist)/kernel.bin $(dist)/isofiles/boot/
	grub-mkrescue -o $(dist)/os.iso $(dist)/isofiles
