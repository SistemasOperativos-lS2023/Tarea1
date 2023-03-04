all:

	rm app.bin

	nasm -f bin boot.asm -o boot.bin

	nasm -f bin mobile-maze.asm -o mobile-maze.bin

	cat boot.bin mobile-maze.bin > app.bin

	rm boot.bin

	rm mobile-maze.bin

	qemu-system-x86_64 -hda app.bin
