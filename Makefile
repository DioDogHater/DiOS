# $@ = target file
# $< = first dependency
# $^ = all dependencies

# First rule is the one executed when no parameters are fed to the Makefile
all: run

build: build/os-image.bin

build/os-image.bin: boot/boot_sector.nasm kernel/* kernel/drivers/*
	nasm $< -f bin -o $@

run: build/os-image.bin
	qemu-system-i386 -no-reboot -fda $<

debug: build/os-image.bin
	qemu-system-i386 -gdb tcp::9000 -S -fda $<

clean:
	rm build/*
