[bits 16]                                      ; Tell nasm to assemble 16 bit code
[org 0x7E00]


;; constants --------------------------------------------------------------------------------------------
KEY_W equ 0x11                              ; scancode for the W key                         
KEY_S equ 0x1F                              ; scancode for the S key
KEY_A equ 0x1E                              ; scancode for the A key
KEY_D equ 0x20                              ; scancode for the D key
KEY_L equ 0x26                              ; scancode for the L key
KEY_R equ 0x13                              ; scancode for the R key
ROWLEN      equ 160	                        ; 80 Character row * 2 bytes each
KEY_ENTER   equ 1Ch	                        ; Keyboard scancodes...
KEY_ESC     equ 01h	

;; set up video mode ------------------------------------------------------------------------------------
mov ax, 0x003                               ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10                                    ; systemcall

; set up video memory -----------------------------------------------------------------------------------
mov ax, 0xB800                              ; load the video memory address into AX register
mov es, ax                                  ; move the video memory address into ES register

;;-------------------------------------------------------------------------------------------------------
initial_menu:
    ; clear the screen with black
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
    call game_delay

    ;; Get Player input
    mov ah, 1			; BIOS get keyboard status int 16h AH 01h
    int 16h
    jz initial_menu	    ; No key entered, don't check, move on

    cbw					; Zero out AH in 1 byte
    int 16h				; BIOS get keystroke, scancode in AH, character in AL
    cmp ah, KEY_ENTER	; Check what key user entered...
    je  game_init        ; Go to game

jmp initial_menu
;; -------------------------------------------------------------------------------------------------------

game_init:
    mov word [playerX], 8
    mov word [playerY], 23
    mov byte [playerSpeedX], 0
    mov byte [playerSpeedY], 0
    mov byte [is_game_paused], -1
    
;; game loop for the game renderization -----------------------------------------------------------------
game_loop:
    ; clear the screen with black
    mov ax, 0xFFFF                          ; set up a white background and black foreground
    xor di, di                              ; clear the DI register
    mov cx, 80*25                           ; set up the number of repetitions
    rep stosw                               ; put AX into [es:di] and increment DI

    ; configure the draw wall's common values to save memory space
    mov ah, 0x80                            ; character config: bg -> 0, fg -> F, char -> 0
    mov byte [wall_direction], 1            ; I wanto ton draw vertical walls

    ; Draw V wall # 1 at X=26, Y=0, L=10          
    mov bx, 26*2                            ; starting x position for v wall #1 and #2
    mov dx, 0                               ; starting y position
    mov cl, 10                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 2 at X=26, Y=12, L=13
    mov dx, 12                              ; starting y position
    mov cl, 13                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 3 at X=42, Y=2, L=21
    mov bx, 42*2                            ; starting x position
    mov dx, 2                               ; starting y position
    mov cl, 21                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 4 at X=62, Y=0, L=24
    mov bx, 62*2                             ; starting x position
    mov dx, 0                               ; starting y position
    mov cl, 24                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 5 at X=78, Y=0, L=11
    mov bx, 78*2                             ; starting x position
    mov dx, 0                               ; starting y position
    mov cl, 11                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 6 at X=78, Y=12, L=13
    mov bx, 78*2                             ; starting x position
    mov dx, 12                               ; starting y position
    mov cl, 13                              ; wall length
    call draw_wall                          ; draw the wall

    ;; common set up for H walls
    mov byte [wall_direction], -1            ; I wanto ton draw horzontal walls
    ; Draw H wall # 1 at X=30, Y=3, W=10
    mov bx, 30*2                             ; starting x position
    mov dx, 3                               ; starting y position
    mov cl, 10                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw H wall # 2 at X=46, Y=24, W=12
    mov bx, 46*2                            ; starting x position
    mov dx, 24                               ; starting y position
    mov cl, 12                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw H wall # 3 at X=68, Y=18, W=10
    mov bx, 68*2                            ; starting x position
    mov dx, 18                               ; starting y position
    mov cl, 10                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw the player on screen
    mov ah, 0x010                           ; character config: bg -> 0, fg -> F, char -> 0
    imul di, [playerY], 160                 ; set player y position                                     
    add di, [playerX]                       ; set player x position                  
    stosw                                   ; move AX into [es:di] and increment DI
    stosw                                   ; move AX into [es:di] and increment DI
    add di, 2*80-4                          ; move a row down

  ; get player input
    mov ah, 1                               ; BIOS get keyboard status
    int 0x16                                ; systemcall
    jz move_player                            ; No key entered, don't check, move on

    mov ah, 0                               ; BIOS set up for key pressed interrupt
    int 0x16                                ; systemcall           

    cmp ah, KEY_W                           ; W key pressed
    je player_up                            ; process player up                      

    cmp ah, KEY_S                           ; S key pressed
    je player_down                          ; process player down

    cmp ah, KEY_D                           ; D key pressed
    je player_right                         ; process player right

    cmp ah, KEY_A                           ; A key pressed
    je player_left                          ; process player left

    cmp ah, KEY_L                           ; L key pressed
    je pause_game                           ; process pause game

    cmp ah, KEY_R                           ; R key pressed
    je restart_game                         ; process restart game


    ;; pause the game
    pause_game:
        neg byte [is_game_paused]           ; enable or disable the pause game flag
        jmp game_tick                       ; continue to the loop

    ;; restart the game
    restart_game:
        jmp game_init

    ;; after the W key is pressed ------------------------------------------------------------------------
    player_up:
        mov byte [playerSpeedX], 0          ; reset player movement in X axis
        mov byte [playerSpeedY], -1         ; invert direction of movement
        jmp move_player                     ; move the player

    ;; after the S key is pressed 
    player_down:
        mov byte [playerSpeedX], 0          ; reset player movement in X axis
        mov byte [playerSpeedY], 1          ; inverti direction of movement
        jmp move_player                     ; move the player

    ;; after the D key is pressed
    player_right:
        mov byte [playerSpeedY], 0          ; reset player movement in Y axis
        mov byte [playerSpeedX], 4          ; inverti direction of movement
        jmp move_player                     ; move the player

    ;; after the D key is pressed
    player_left:
        mov byte [playerSpeedY], 0          ; reset player movement in Y axis
        mov byte [playerSpeedX], -4         ; inverti direction of movement
        jmp move_player                     ; move the player

    ;; Move the player
    move_player:
        cmp byte [is_game_paused], 1        ; is_game_paused equals to 1??           
        je game_tick                        ; if yes, pause the game
        mov bl, [playerSpeedX]              ; laod the X speed into BL register
        add [playerX], bl                   ; add the X speed to the player X position
        
        mov bl, [playerSpeedY]              ; load the Y speed into BL register
        add [playerY], bl                   ; add the Y speed to the player Y position

    ;; check top collision ------------------------------------------------------------------------------
    check_top_collision:
        cmp word [playerY], 0               ; compare player Y position with 1
        jg check_bottom_collision           ; if player Y position is greater than 1, continue the check
        neg byte [playerSpeedY]             ; otherwise, invert the player Y direction

    ;; check bottom collision
    check_bottom_collision:
        cmp word [playerY], 24              ; compare player Y position with 24
        jl check_left_collision             ; if player Y position is less than 24, continue the check
        neg byte [playerSpeedY]             ; otherwise, invert the player Y direction

    ;; check left collision
    check_left_collision:
        cmp word [playerX], 2               ; compare player X position with 2
        jg check_right_collision            ; if player X position is greater than 2, continue the check
        mov byte [playerSpeedX], 4          ; otherwise, invert the player X direction

    ;; check right collision
    ;; This is the winning level checkpoint
    check_right_collision:
        cmp word [playerX], 154             ; compare player X position with 2
        jl  check_wall_collisions                     ; if player X position is less than 154, continue to game_tick
        mov byte [playerSpeedX], -4         ; otherwise, invert the player X direction


    ;; check vertical walls collisions  ----------------------------------------------------------------
   


    check_wall_collisions:
        mov byte [wall_direction], 1                ; chek for vertical walls

        ;;  check collision with V wall # 1 at X=26, Y=0, L=10
        mov bx, 26*2                                 ; wall's x position * 2
        mov dx, 0                                   ; wall's y position 
        mov cx, 10-1                                  ; wall's length - 1
        call wall_collision

        ; chek collision with V wall # 2 at X=26, Y=12, L=13
        mov bx, 26*2                                 ; wall's x position * 2
        mov dx, 12                                   ; wall's y position 
        mov cx, 13-1                                  ; wall's length - 1
        call wall_collision

        ; chek collision with V wall # 3 at X=42, Y=2, L=21
        mov bx, 42*2                                 ; wall's x position * 2
        mov dx, 2                                   ; wall's y position 
        mov cx, 21-1                                  ; wall's length - 1
        call wall_collision

        ; chek collision with V wall # 4 at X=62, Y=0, L=24
        mov bx, 62*2                                 ; wall's x position * 2
        mov dx, 0                                   ; wall's y position 
        mov cx, 24-1                                  ; wall's length - 1
        call wall_collision

        ; chek collision with V wall # 5 at X=78, Y=0, L=11
        mov bx, 78*2                                 ; wall's x position * 2
        mov dx, 0                                   ; wall's y position 
        mov cx, 11-1                                  ; wall's length - 1
        call wall_collision

        ; chek collision with V wall # 6 at X=78, Y=12, L=13
        mov bx, 78*2                                 ; wall's x position * 2
        mov dx, 12                                   ; wall's y position 
        mov cx, 13-1                                  ; wall's length - 1
        call wall_collision


        neg byte [wall_direction]                     ; chek for horizontal walls
        
        ; chek collision with H wall # 1 at X=30, Y=3, W=10
        mov bx, 30*2                                 ; wall's x position * 2
        mov dx, 3                                   ; wall's y position 
        mov cx, (10-1)*2                             ; (wall's wide - 1) *2
        call wall_collision

        ; chek collision with H wall # 2 at X=46, Y=24, W=12
        mov bx, 46*2                                 ; wall's x position * 2
        mov dx, 24                                   ; wall's y position 
        mov cx, (12-1)*2                             ; (wall's wide - 1) *2
        call wall_collision

        ; chek collision with H wall # 3 at X=68, Y=18, W=10
        mov bx, 68*2                                 ; wall's x position * 2
        mov dx, 18                                   ; wall's y position 
        mov cx, (10-1)*2                             ; (wall's wide - 1) *2
        call wall_collision





    ;; game delay time before rendering the screen's content again
    game_tick:
        mov bx, [0x046C]                        ; load the BIOS timer value into BX
        inc bx                                  ; increment BX register
        inc bx                                  ; increment BX register
        .delay:
            cmp [0x046C], bx                    ; compare if the tick has reached the incremented value
            jl .delay                           ; if not, delay

    jmp game_loop                               ; repeat the game loop                 
;; end of game loop --------------------------------------------------------------------------------------

;; ******************************************************************************************************
;; procedure to clear the screen with black color
;; argument: bx (the color and character combination)
clear_screen:
    mov ax, bx
    xor di, di
    mov cx, 80*25
    rep stosw
    ret
;; ******************************************************************************************************

;; ******************************************************************************************************
;; procedure to clear the screen with black color
;; argument: bx (the color and character combination)
game_delay:
    mov bx, [0x046C]                        ; load the BIOS timer value into BX
    inc bx                                  ; increment BX register
    inc bx                                  ; increment BX register
    .delay:
        cmp [0x046C], bx                    ; compare if the tick has reached the incremented value
        jl .delay                           ; if not, delay
        ret
;; ******************************************************************************************************

;; ******************************************************************************************************
;; procedure to cprint a string on screen
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
;; ******************************************************************************************************

;; ******************************************************************************************************
;; procedure to reset player position and movement
reset_player_parameters:
    mov word [playerX], 4                   ; reset player's x position
    mov word [playerY], 10                  ; reset player's y position
    mov byte [playerSpeedX], 0              ; cancel player's x movement
    mov byte [playerSpeedY], 0              ; cancel player's y movement
    ret
;; ******************************************************************************************************

;; ******************************************************************************************************
;; Draw wall procedure -----------------------------------------------------------------------------------
;; arguments: AH register, BH register, DX register, CH register
;; AH register: The charcter config --> bg:fg:char
;; BX register: The wall x position
;; DX register: The wall y position
;; CL register: The wall legth or width
;; [wall direction]: 1 is the wall is vertical and -1 if the wall is horizontal
 
draw_wall:
    imul di, dx, 160                        ; set the wall's Y posotion from DX register                                            
    add di, bx                              ; add the wall's X position
    cmp byte [wall_direction], -1           ; compare wall_direction value with -1
    je  .draw_h_wall_loop                   ; if true, go draw a horizontal wall                          
    .draw_v_wall_loop:
        stosw                                   ; put AX into [es:di] and increment DI                         
        stosw                                   ; put AX into [es:di] and increment DI                         
        add di, 2*80-2*2                          ; move a row down
        loop .draw_v_wall_loop                  ; repeat CX times
        ret                                     ; return
    .draw_h_wall_loop:
        stosw
        loop .draw_h_wall_loop
        ret
;; ******************************************************************************************************

;; ******************************************************************************************************
;; Wall collision procedure
;; [wall_direction] 1 for vertical walls and -1 for horizontal walls
;; BX register: wall's x position
;; DX register: wall's y position
;; CX register: wall's length or width
wall_collision:
    cmp byte [wall_direction], -1           ; compare the wall_direction value with -1
    je .horizontal_collision                ; if equal, check vertical collision
    jmp .vertical_collision

    .vertical_collision:
        cmp word [playerX], bx              ; compare player and wall's x position
        je .check_vertical_boundaries       ; if equals, check if player is under the wall's length range
        jmp .return_wall_collision          ; if not, return
        
        .check_vertical_boundaries:
            cmp word [playerY], dx          ; compare player and walls's starting y position
            jl .return_wall_collision       ; if player is above the wall's starting y position, return
            add dx, cx                      ; add the wall's length to the wall's starting y point
            cmp word [playerY], dx          ; compare the player y position with the wall's lower boundary
            jg .return_wall_collision       ; if greater, return
            jmp .kill_player                ; otherwise, it's a collision

    .horizontal_collision:
        cmp word [playerY], dx              ; compare player and wall's y position
        je .check_horizontal_boundaries     ; if equals, check if player is under the wall's wide range
        jmp .return_wall_collision          ; if not, return
        
        .check_horizontal_boundaries:
            cmp word [playerX], bx          ; compare player and walls's starting x position
            jl .return_wall_collision       ; if player is above the wall's starting y position, return
            add bx, cx                      ; add the wall's length to the wall's starting y point
            cmp word [playerX], bx           ; compare the player y position with the wall's lower boundary
            jg .return_wall_collision       ; if greater, return
            jmp .kill_player                 ; otherwise, it's a collision

    .kill_player:
        call reset_player_parameters        ; reset player position and movement values

    .return_wall_collision:
        ret





;;============== VARIABLES ==============
drawColor: dw 0F020h
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
is_game_paused: db -1
playerY: dw 10                              ; starting y position for the player
playerX: dw 4                               ; starting x position for the player
playerSpeedX: db 0                          ; player x speed              
playerSpeedY: db 0                          ; player y speed
wall_direction: db 1                        ; to notice if the wall is v or h

level: db 1                       ; 1 for the beginner level and -1 for the advanced level
times 2048-($-$$) db 0
