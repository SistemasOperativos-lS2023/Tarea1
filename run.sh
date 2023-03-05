# assemble bootloader
nasm -f bin bootloader.asm -o bootloader.bin

# assemble game
nasm -f bin mobile-maze.asm -o mobile-maze.bin

# generate floppy image (2880 - 5 sectors used = 2875)
dd if=/dev/zero of=floppy.bin count=2875 bs=512

# merge bootloader into floppy image
cat bootloader.bin mobile-maze.bin \
    floppy.bin > GameOS.img

xxd the-game.bin

# clean up files
rm -f bootloader.bin floppy.bin mobile-maze.bin

# run OS image in the QEMU emulator (NOTE we load image from HDD not from FLOPPY!)
qemu-system-i386 -hda GameOS.img