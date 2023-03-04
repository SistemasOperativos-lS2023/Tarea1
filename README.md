# Tarea1
This repository contains the whole development history of  "Mobile maze booteable" project


#Boot Loader:

	How to run and install qemu?
		- sudo apt-get install qemu qemu-kvm #Install
		- nasm -f bin boot.asm -o boot.bin #Run
		- qemu-system-x86_64 -fda boot.bin #Run

	How to install and run bochs?
		- sudo apt-get install bochs bochs-x #Install
		- nasm -f bin boot.asm -o boot.bin #Run
		- bochs #Run

	How to generate img?
		- nasm -f bin boot.asm -o boot.img
		- xxd boot.img (verify img size)

#Load img to HD

	Clear HD:
		- sudo dd if=/dev/zero of=/dev/sdd count=2880 bs=512

	Paste img on HD:
		- sudo dd if=boot.img of=/dev/sdd count=2880 bs=512




- lsusb
- sudo qemu-system-x86_64 -m 512  -usb -device usb-host,hostbus=usbBusNum,hostaddr=#usbDevNum
