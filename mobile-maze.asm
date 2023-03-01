[bits 16]                       ; Tell nasm to assemble 16 bit code
[org 0x7C00]                    ; Tell nasm the code is running at boot sector

; set up video mode
mov ax, 0x003                   ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10

; set up video memory
mov ax, 0xB800
mov es, ax ; ES:DI <-- B800:0000

game_loop:
    xor ax, ax                  ; AX is the data to store
    xor di, di                  ; DI is the pointer
    mov cx, 80*25               ; CX register equals to 80*25
    rep stosw                   ; stosw stores AX into [ES:DI]and then increments DI
    
jmp game_loop

times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature