# assemble bootloader
nasm -f bin bootloader.asm -o bootloader.bin

# assemble shell
nasm -f bin the-game.asm -o the-game.bin

# generate floppy image (2880 - 5 sectors used = 2875)
dd if=/dev/zero of=floppy.bin count=2875 bs=512

# merge bootloader into floppy image
cat bootloader.bin the-game.bin \
    floppy.bin > GameOS.img

xxd the-game.bin

# clean up files
rm -f bootloader.bin floppy.bin the-game.bin

# run OS image in the QEMU emulator (NOTE we load image from HDD not from FLOPPY!)
qemu-system-i386 -hda GameOS.img