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
    mov si, obstaculosSuperados
    call video_string

    ;Pintando los comandps de; juegos 
    mov si, comando
    call video_string

    ;Se llama a la funcion de suma unitaria 
    jmp restaUnitariaCronometro
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
        mov ah, 0x07
        stosw             
        jmp video_string          

    .return: ret           

;Suma un valor determinado 
sumarObstaculos:
    mov cl, [obstaculosSuperados]; Se guarda el valor del dato, que toma de manera decimal cuantos obstaculos superados tiene
    mov dl, [valor]; En dl se guarda la cantida de muros superados que se le desa agregar
    add cl, dl ;Se suman los datos 
    mov [obstaculosSuperados],cl ;Se guarda en memoria el valor decimal de los obstaculos superados

obstaculosSuperadosConversionASQUII:
    mov cx, [obstaculosSuperados] ;Se guardad el valor actual de los obstaculos superados
    cmp cx, 9 ;Se compara con nuevo
    jg convertirAsquiiDosDigitos ;En caso de que cx sea mayot a nueve se hace un salto para crear asquii para el valor de obstaculos superados
    jmp convertirAsquiiUnDigito ;En caso que cx, se igual o menor a nueve saltamos a cerar un asquii para los osbtaculos superados


;Si el valor de contador es mayor a 9 y menor a 99 convertimos en ASQII en 2 digitos
convertirObstaculosAsquiiDosDigitos:
    mov ax, [obstaculosSuperados] ;Guardamos el valor de los obstaculos superados en ax
    mov bl, 10 ;Dividimos entre 10 el bl
    div bl
    add al,48 ;Se le suma 48 al cociente de la salida de la division
    add ah,48 ;Se le suma 48 al resultado de la division 
    mov [obstaculosSuperadosAsquii], ax ;Se guarda el valor de cx en osbtaculos superados
    
;Si el valor de contador es menor a 9 y  1 digitos
convertirObstaculosAsquiiUnDigito:
    add cx, 48 ; Se le suma  48 a cx
    mov [obstaculosSuperadosAsquii], cx ;Se guarda el valor de cx en osbtaculos superados


;Se realiza una suma unitaria la cual, nos permite el control de la variable cronometro
restaUnitariaCronometro:
    mov cx, [controlTiempo] ; Se guarda en en cx el controlador del tiempo
    add cx,1 ;Se le suma uno
    mov [controlTiempo],cx ; Se guarda en control de tiempo 
    cmp cx,9 ;Compara los datos con bueve
    jl prueba ; Hace un salto cuando cx es igual a nueve

;Se realiza una fucnion para convertir el control del cronometro
convertirContadorASQII:
    mov cx,0 ;Se reinicia valor de cx
    mov [controlTiempo],cx ;El control de tiempo se devuelve a 0
    mov cx, [contadorCronometro] ;Se guarda el valor de contador de tiempo
    sub cx, 1 ;Se le resta uno 
    mov [contadorCronometro], cx ;El se suma uno al contador cronometro
    cmp cx, 9 ; Se compara el valor de cx con 9 
    jg convertirAsquiiDosDigitos ;Si es mayor a nueve salta a convertir valor de dos digitos
    jmp convertirAsquiiUnDigito ;Si es menor o o igual a nueve salta a ASQUII de un digito


;Si el valor de contador es mayor a 9 y menor a 99 convertimos en ASQII en 2 digitos
convertirAsquiiDosDigitos:
    mov ax, [contadorCronometro] ;Se guarda el valor de contador cronometro 
    mov bl, 10 ; Se divide el valor de ax en 10
    div bl
    add al,48 ;Se le suma 48 al residuo de la division
    add ah,48 ;Se le suma 48 al resultado de la division
    mov [cronometro], ax; Se el valor de ax cronometro
    jmp prueba ;Se hace una salto a prueba
    
;Si el valor de contador es menor a 9 y  1 digitos
convertirAsquiiUnDigito:
    add cx, 48 ;Se le suma 48 al valor de cx
    mov [cronometro], cx ;Se guarda el valor de cxx
    jmp prueba ; Se hace una salto a prueba


; Variables utilizadas para guardar en memoria 
nombreD: db 'Nombre: ', 0
nombre: db 'Jason', 0
nivel: db ' Nivel:',0
nivelN: db '1',0

obstaculos: db ' Obstaculos: ', 0

obstaculosSuperados: db '', 0
valor db 0
obstaculosSuperadosAsquii: dw '' 

comando: db " Comandos:P,R,^,<,>,v Tiempo: ", 0

controlTiempo dw 0
contadorCronometro dw 30 
cronometro dw '', 0

times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature