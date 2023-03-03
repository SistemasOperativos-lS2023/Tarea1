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

    ;Pintado nivel    
    mov si, nivel
    call video_string

    ;Pintando el nivel actual
    mov si, nivelN
    call video_string
    
    ;Pintando Obstaculos
    mov si, obstaculos
    call video_string

    ;Pintando Obstaculos Superados
    mov si, obstaculosN
    call video_string

    ;Pintando los comandps de; juegos 
    mov si, comando
    call video_string

    ;Se llama a la funcion de suma unitaria 
    jmp sumaUnitaria
    ;Se pinta el numero actualmente es un cronometro
    prueba:
        mov si, cronometro;
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

;Se realiza una suma unitaria la cual, nos permite el control de la variable cronometro
sumaUnitaria:
    mov cx, [control]
    add cx,1
    mov [control],cx
    cmp cx,9
    jl prueba
;Se realiza una fucnion para convertir el control del cronometro
convertirContadorASQII:
    mov cx,0
    mov [control],cx 
    mov cx, [contador]
    add cx, 1
    mov [contador], cx
    cmp cx, 9
    jg convertirAsquiiDosDigitos
    jmp convertirAsquiiUnDigito

;Si el valor de contador es mayor a 9 y menor a 99 convertimos en ASQII en 2 digitos
convertirAsquiiDosDigitos:
    mov ax, [contador]
    mov bl, 10
    div bl
    add al,48
    add ah,48
    mov [cronometro], ax
    jmp prueba 
    
;Si el valor de contador es menor a 9 y  1 digitos

convertirAsquiiUnDigito:
    add cx, 48
    mov [cronometro], cx
    jmp prueba





nombreD: db 'Nombre: ', 0
nombre: db 'Jason', 0
nivel: db ' Nivel:',0
nivelN: db '1',0
obstaculos: db ' Obstaculos: ', 0
obstaculosN: db '123', 0
comando: db " Comandos:P,R,^,<,>,v Contador: ", 0
control dw 0
contador dw 0 
cronometro dw '', 0
times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature