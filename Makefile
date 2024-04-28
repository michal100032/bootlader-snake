.PHONY: run

build/floppy.img: src/main.asm
	mkdir -p build
	nasm -f bin src/main.asm -o build/floppy.img

run: build/floppy.img
	qemu-system-x86_64 -cpu 486 -drive format=raw,file=build/floppy.img
