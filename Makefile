# $@ = target file
# $< = first dependency
# $^ = all dependencies

# First rule is the one executed when no parameters are fed to the Makefile
all: run

build: build/os-image.bin

build/os-image.bin: boot/boot_sector.nasm kernel/* kernel/drivers/* kernel/cpu/* stdlib/*
	nasm $< -f bin -o $@

build/disk.img:
	qemu-img create $@ -f qcow2 128M

run: build/os-image.bin build/disk.img
	qemu-system-i386 -m 512 -fda $< -hda build/disk.img

clean:
	rm build/*
