[bits 16]                                      ; Tell nasm to assemble 16 bit code
[org 0x7E00]

mov ax, 0                       ; set ACCUMULATOR REGISTER to 0
mov ds, ax                      ; set DATA SEGMENT to 0
mov es, ax                      ; set EXTRA SEGMENT to 0

mov ax, 0x003                   ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10

; set up video memory
mov ax, 0xB800
mov es, ax ; ES:DI <-- B800:0000


;;============== CONSTANTES ==============
ROWLEN      equ 160	; 80 Character row * 2 bytes each
KEY_ENTER   equ 1Ch	; Keyboard scancodes...
KEY_ESC     equ 01h	
KEY_R       equ 13h



;;============== VARIABLES ==============
drawColor: dw 0F020h



initial_menu:
    ; Poner pantalla en color negro
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    mov si, welcome
    mov di, ROWLEN*8+54    ;160 espacios*no.linea + offset
    call video_string

    mov si, confirmation
    mov di, ROWLEN*13+54   ;160 espacios*no.linea + offset
    call video_string

    ;; Draw color borders
	mov ax, [drawColor]	; White bg, black fg
	mov di, 0			; Start at 0
    mov bx, ROWLEN*24
	mov cl, 40			; cl # of times
	.draw_borders_loop:
		stosw
        add word [drawColor], 1000h		; Move to next VGA color
        mov ax, [drawColor]	            ; White bg, black fg  
        mov [es:di], ax   
        mov [es:bx], ax   
		add di, 2		                ; Move 2
        add bx, 4
		loop .draw_borders_loop	        ; Loops cl # of times
    
    ; Delay
    mov bx, [0x046C]
    add bx, 0x0a
    .delay:
        cmp [0x046C], bx
        jl .delay

    ;; Get Player input
    mov ah, 1			; BIOS get keyboard status int 16h AH 01h
    int 16h
    jz initial_menu	    ; No key entered, don't check, move on

    cbw					; Zero out AH in 1 byte
    int 16h				; BIOS get keystroke, scancode in AH, character in AL
    cmp ah, KEY_ENTER	; Check what key user entered...
    je game_won        ; Go to game

jmp initial_menu


;;============= LOOP DEL JUEGO =============

game_loop:
    ; Poner pantalla en color negro
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    ; pintar el nombre
    mov si, nombreD
    mov di, ROWLEN*1+4
    call video_string
    
    ; pintar el nombre de Jason
    mov si, nombre
    call video_string

    ;Pintado nivel    
    mov si, nivel
    mov di, ROWLEN*2+2
    call video_string

    ;Pintando el nivel actual
    mov si, nivelN
    call video_string
        
    ;Pintando Obstaculos
    mov di, ROWLEN*3+2
    mov si, obstaculos
    call video_string

    ;Pintando Obstaculos Superados
    mov si, obstaculosN
    call video_string


    ;Pintando los comandos de; juegos
    mov di, ROWLEN*4+2 
    mov si, comando
    call video_string

    ; game loop
    mov bx, [0x046C]
    inc bx
    inc bx
    .delay:
        cmp [0x046C], bx
        jl .delay


     ;;if ganó: jmp game_won  

jmp game_loop


;;=========== PANTALLA GANE ===========

game_won:
    mov ax, 0x802                   ; init the segment
    mov es, ax                      ; init EXTRA SEGMENT register
    mov bx, 0                       ; init local offset within the segment
    mov cl, 4                       ; sector 4 on USB flash drive contains the game
    call read_sectors                ; read sector from USB flash drive
    jmp 0x802:0x0000                ; jump to rhe shell executable and run it



;;=========== FUNCIONES ==========

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

color_video_string:
    xor ax, ax            
    .color_next_char:
        lodsb               
        cmp al, 0              
        je .return
        mov ah, [drawColor]
        add byte [drawColor], 10h		; Move to next VGA color     
        stosw   
        jmp color_video_string          

    .return: ret    



; procedure to print a string
print_string:
    cld                         ; clear direction flag
    mov ah, 0x0e                ; enable teletype output for 0x10 BIOS interrupt
    
    .next_char:                 ; print next char
        lodsb                   ; read next byte from SOURCE INDEX register
        cmp al, 0               ; match the zero terminating char of the string
        je .return              ; return if string doesn't contain any chars any more
        int 0x10                ; assuming ah = 0x0e int 0x10 would print a single char
        jmp .next_char          ; repeat printing char until string is fully printed
    
    .return: ret                ; return from procedure

; procedure to read a single sector from USB flash drive
read_sectors:
    mov ah, 0x02                ; BIOS code to READ from storage device
    mov al, 2                   ; how many sectors to read
    mov ch, 0                   ; specify celinder
    mov dh, 0                   ; specify head
    mov dl, 0x80                ; specify HDD code
    int 0x13                    ; read the sector from USB flash drive
    jc .error                   ; if failed to read the sector handle the error
    ret                         ; return from procedure
    
    .error:
        mov si, error_message   ; point SOURCE INDEX register to error_message string's address
        call print_string       ; print error message
        jmp $                   ; stuck here forevevr (infinite loop)

; messages
error_message db 'Failed to read sector from USB!', 10, 13, 0



win: db 'Ha ganado!',0
restart: db 'Reiniciar el juego [R]', 0
exit: db 'Salir al menu [ESC]', 0
welcome: db 'Bienvenido a Mobile Maze!', 0
confirmation: db 'Presione ENTER para jugar!', 0
nombreD: db 'Nombre: ', 0
nombre: db 'Jason', 0
nivel: db ' Nivel:',0
nivelN: db '1',0
obstaculos: db ' Obstaculos: ', 0
obstaculosN: db 0, 0
comando: db " Comandos: P,R,^,<,>,v", 0
times 512 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file