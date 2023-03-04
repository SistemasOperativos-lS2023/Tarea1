all:
	nasm -f bin shell.asm -o shell.bin
	qemu-system-i386 -drive file=shell.bin,index=0,media=disk,format=raw
	xxd shell.bin
	rm -f shell.bin
