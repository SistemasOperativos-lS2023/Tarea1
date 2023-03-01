all:
	nasm -f bin mobile-maze.asm -o mobile-maze.img

run:
	qemu-system-i386 -drive file=mobile-maze.img,index=0,media=disk,format=raw

clean:
	rm -f mobile-maze.img