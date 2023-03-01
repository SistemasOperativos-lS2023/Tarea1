[bits 16]                       ; Tell nasm to assemble 16 bit code
[org 0x7C00]                    ; Tell nasm the code is running at boot sector

; set up video mode
mov ax, 0x003                   ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10

; set up video memory
mov ax, 0xB800
mov es, ax ; ES:DI <-- B800:0000



game_loop:
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    ; pintar el nombre
    mov si, nombreD
    mov di, 1*2
    call video_string
    
    ; pintar el nombre de Jason
    mov si, nombre
    call video_string



    ; game loop
    mov bx, [0x046C]
    inc bx
    inc bx
    .delay:
        cmp [0x046C], bx
        jl .delay
jmp game_loop


video_string:
    xor ax, ax            
    .next_char:
        lodsb               
        cmp al, 0              
        je .return              
        mov ah, 0x0F
        stosw             
        jmp video_string          

    .return: ret                



nombreD: db 'Nombre: ', 0
nombre: db 'Jason', 0

obstaculos: db 'Obstaculos superados: ', 0
times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature