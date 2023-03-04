org 0x7C00 			; Tell nasm the code is running at boot sector

initialize:

    READ:      EQU 0x02
    STACK_ADD: EQU 0x6ef0

boot:
    cli				; Disable interruptions

    cld 			; Ensure direction flag is cleared (for LODSB)
    xor ax, ax
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, STACK_ADD

    sti				; Enable interruptions

    mov ah, READ 		; BIOS read sector function
    mov al, 1 			; Number of sectors to read
    mov ch, 0 			; Cylinder number
    mov dh, 0 			; Head number
    mov cl, 2 			; Sector number
    ;mov dl, 0x80 		; Boot drive number
    mov bx, 0x8000 		; Load sector into address 0x8000
    int 0x13 			; Interrupt BIOS
   
    jmp 0:0x8000		; Go to the initial page 


times 446-($-$$) db 0
db 0x80                   ; bootable
db 0x00, 0x01, 0x00       ; start CHS address
db 0x17                   ; partition type
db 0x00, 0x02, 0x00       ; end CHS address
db 0x00, 0x00, 0x00, 0x00 ; LBA
db 0x02, 0x00, 0x00, 0x00 ; number of sectors

times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature
