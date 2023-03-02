[bits 16]                       ; Tell nasm to assemble 16 bit code
[org 0x7C00]                    ; Tell nasm the code is running at boot sector

; set up video mode
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
drawColor: dw 0F0h



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

    mov si, vga_border
    mov di, 0 
    call color_video_string

    mov si, vga_border
    mov di, ROWLEN*24
    call color_video_string
    
    ; Delay
    mov bx, [0x046C]
    inc bx
    inc bx
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
    je game_loop        ; Go to game

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
    ; Poner pantalla en color negro
    ;xor ax, ax
    ;xor di, di
    ;mov cx, 80*25
    ;rep stosw

    mov si, win 
    mov di, ROWLEN*8+70    ;160 espacios*no.linea + offset
    call color_video_string

    mov si, restart
    mov di, ROWLEN*20+20
    call video_string

    mov si, exit
    mov di, ROWLEN*20+100
    call video_string
    
    ; Delay
    ;mov bx, [0x046C]
    ;inc bx
    ;inc bx
    ;.delay:
    ;    cmp [0x046C], bx
    ;    jl .delay

    get_player_input:
		;; Get Player input
		mov ah, 1			; BIOS get keyboard status int 16h AH 01h
		int 16h
		jz game_won		; No key entered, don't check, move on

		cbw					; Zero out AH in 1 byte
		int 16h				; BIOS get keystroke, scancode in AH, character in AL
			
		cmp ah, KEY_ESC		; Check what key user entered...
		je esc_pressed
		cmp ah, KEY_R
		je r_pressed

		jmp game_won		; Otherwise user entered some other key, move on, don't worry about it

	;; Salir --> ir al menú inicial
	esc_pressed:
		jmp initial_menu

	;; Reset game to initial state
	r_pressed:
        jmp game_loop   ;(?)
		;int 19h			; Reloads the bootsector (in QEMU)

jmp game_won




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


vga_border: db '                                                                                ',0                    
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
obstaculosN: db '123', 0
comando: db " Comandos: P,R,^,<,>,v", 0
times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature
