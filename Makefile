# $@ = target file
# $< = first dependency
# $^ = all dependencies

# First rule is the one executed when no parameters are fed to the Makefile
all: run

build: build/os-image.bin

build/os-image.bin: boot/boot_sector.asm kernel/* kernel/drivers/*
	nasm $< -f bin -o $@

run: build/os-image.bin
	qemu-system-x86_64 -fda $<

debug: build/os-image.bin
	qemu-system-x86_64 -gdb tcp::9000 -S -fda $<

clean:
	rm build/*