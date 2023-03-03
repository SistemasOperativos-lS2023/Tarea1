all:
	nasm -f bin mobile-maze.asm -o mobile-maze.bin
	qemu-system-i386 -drive file=mobile-maze.bin,index=0,media=disk,format=raw
	xxd mobile-maze.bin
	rm -f mobile-maze.bin
