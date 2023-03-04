# assemble bootloader
nasm -f bin bootloader.asm -o bootloader.bin

# assemble game list
nasm -f bin start-menu.asm -o start-menu.bin

# assemble game list
nasm -f bin files.asm -o files.bin

# assemble shell
nasm -f bin mobile-maze.asm -o mobile-maze.bin

# generate floppy image (2880 - 5 sectors used = 2875)
dd if=/dev/zero of=floppy.bin count=2875 bs=512

# merge bootloader into floppy image
cat bootloader.bin start-menu.bin files.bin mobile-maze.bin \
    floppy.bin > GameOS.img

# clean up files
rm -f bootloader.bin floppy.bin files.bin mobile-maze.bin start-menu.bin

# run OS image in the QEMU emulator (NOTE we load image from HDD not from FLOPPY!)
qemu-system-i386 -hda GameOS.img