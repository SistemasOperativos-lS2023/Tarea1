                                  ; Tell nasm to assemble 16 bit code
org 7c00h                             ; Tell nasm the code is running at boot sector

;; constants --------------------------------------------------------------------------------------------
KEY_W equ 0x11                              ; scancode for the W key                         
KEY_S equ 0x1F                              ; scancode for the S key
KEY_A equ 0x1E                              ; scancode for the A key
KEY_D equ 0x20                              ; scancode for the D key
KEY_L equ 0x26                              ; scancode for the L key
KEY_R equ 0x13
;; set up video mode ------------------------------------------------------------------------------------
mov ax, 0x003                               ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10                                    ; systemcall

; set up video memory -----------------------------------------------------------------------------------
mov ax, 0xB800                              ; load the video memory address into AX register
mov es, ax                                  ; move the video memory address into ES register


;; game loop for the game renderization -----------------------------------------------------------------
game_loop:
    ; clear the screen with black
    mov ax, 0xFFFF                          ; set up a white background and black foreground
    xor di, di                              ; clear the DI register
    mov cx, 80*25                           ; set up the number of repetitions
    rep stosw                               ; put AX into [es:di] and increment DI

    ; print a string
    mov si, nombre                          ; load string's first index from memory
    mov di, 2                               ; indicate the position on screen
    call video_string                       ; print the string

    ; configure the draw wall's common values to save memory space
    mov ah, 0x30                            ; character config: bg -> 0, fg -> F, char -> 0

    ; Draw V wall # 1          
    mov bx, 40                              ; starting x position for v wall #1 and #2
    mov dx, 1                               ; starting y position
    mov cl, 10                              ; wall length
    call draw_wall                          ; draw the wall

    ;Draw V wall # 2
    mov dx, 14                              ; starting y position
    mov cl, 11                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 3
    mov bx, 80                             ; starting x position
    mov dx, 3                               ; starting y position
    mov cl, 22                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 4
    mov bx, 120                             ; starting x position
    mov dx, 1                               ; starting y position
    mov cl, 22                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 5
    mov bx, 156                             ; starting x position
    mov dx, 3                               ; starting y position
    mov cl, 22                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw the player on screen
    mov ah, 0xF00                           ; character config: bg -> 0, fg -> F, char -> 0
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
               
    ;; after the W key is pressed
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


    ;; reatart the game
    restart_game:
        mov byte [playerSpeedX], 0
        mov byte [playerSpeedY], 0
        mov word [playerX], 4
        mov word [playerY], 10
        jmp game_tick

    ;; pause game
    pause_game:
        neg byte [is_game_paused]           ; negates the is_game_paused_flag
        
    ;; Move the player
    move_player:
        cmp byte [is_game_paused], 1        ; is_game_paused equals to 1??           
        je game_tick                        ; if yes, pause the game
        mov bl, [playerSpeedX]              ; laod the X speed into BL register
        add [playerX], bl                   ; add the X speed to the player X position
        
        mov bl, [playerSpeedY]              ; load the Y speed into BL register
        add [playerY], bl                   ; add the Y speed to the player Y position

    ;; check top collision
    check_top_collision:
        cmp word [playerY], 1               ; compare player Y position with 1
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
        jl check_v_walls_collision          ; if player X position is less than 154, continue to game_tick
        mov byte [playerSpeedX], -4         ; otherwise, invert the player X direction

;; check if player is colliding with any of the walls placed at the screen
check_v_walls_collision:
    ;; check collision with V wall # 1
    mov al, 1                               ; it is an upper wall
    mov bx, 40                              ; wall's x position
    mov cx, 11-1                            ; wall's length
    call v_wall_collision_stage_1           ; check collision

    ;; check collision with V wall # 2
    mov al, 0                               ; it is a lower wall
    mov bx, 40                              ; wall's x position
    mov cx, 14                              ; wall's y start position
    call v_wall_collision_stage_1           ; check collision

    ;; check collision with V wall # 3
    mov al, 0                               ; it is a lower wall
    mov bx, 80                              ; wall's x position
    mov cx, 3                               ; wall's y start position
    call v_wall_collision_stage_1           ; check collision

    ;; check collision with V wall # 4
    mov al, 1                               ; it is an upper wall
    mov bx, 120                             ; wall's x position
    mov cx, 23-1                            ; wall's length
    call v_wall_collision_stage_1           ; check collision

    ;; check collision with V wall # 5
    mov al, 0                               ; it is lower wall
    mov bx, 156                             ; wall's x position
    mov cx, 3                               ; wall's y start position
    call v_wall_collision_stage_1           ; check collision 

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

;; Video string procedure --------------------------------------------------------------------------------
;; arguments: SI register, DI register
;; SI register: The pointer to the string starting address
;; DI register: The place (times 2 bytes) where you want to start placing the first char on screen 
video_string:
    lodsb                                   ; put the charcter from SI into AL              
    cmp al, 0                               ; is the current char the end of the string????             
    je .return                              ; if true, then return     
    mov ah, 0xF0                            ; otherwise, set up the character set up
    stosw                                   ; put AX into [es:di] and increment DI                                    
    jmp video_string                        ; continue with the next char from the string                      
.return: ret                                ; return from procedure             

;; Draw wall procedure -----------------------------------------------------------------------------------
;; arguments: AH register, BH register, DX register, CH register
;; AH register: The charcter config --> bg:fg:char
;; BX register: The wall x position
;; DX register: The wall y position
;; CL register: The wall legth or width
;; [wall direction]: 1 is the wall is vertical and 0 if the wall is horizontal
 
draw_wall:
    imul di, dx, 160                        ; set the wall's Y posotion from DX register                                            
    add di, bx                              ; add the wall's X position                             
.draw_v_wall_loop:
    stosw                                   ; put AX into [es:di] and increment DI                         
    stosw                                   ; put AX into [es:di] and increment DI                         
    add di, 2*80-4                          ; move a row down
    loop .draw_v_wall_loop                  ; repeat CX times
    ret                                     ; return

;; wall collision procedure ------------------------------------------------------------------------------
;; providing the wall x position, y position, and wall length
;; AL register: 1 is the wall is up, 0 is wall is down
;; BX register: The wall x position
;; CX register: wall y position if AL is 0, wall (y position + length - 1) if AL is 1
v_wall_collision_stage_1:
    cmp word [playerX], bx                  ; player x position is the same as wall x position
    je  v_wall_collision_stage_2            ; go check if player y is on the wall's y position range
    jmp return_wall_collision               ; if not, return from the procedure

v_wall_collision_stage_2:
    cmp al, 1                               ; is the wall above??
    je  v_wall_collision_upY                ; check up condition

v_wall_collision_downY:
    cmp word [playerY], cx                  ; compare the player y position with the wall length
    jl return_wall_collision                ; if player is above the wall's y position, then return
    jmp kill_player                         ; otherwise, game over               

v_wall_collision_upY:
    cmp word [playerY], cx                  ; compare the player y position with the wall length
    jg  return_wall_collision               ; if player is under the wall's y position, then return
    jmp kill_player                         ; kill the player

kill_player:
    mov byte [playerSpeedX], 0              ; disable player speed
    mov byte [playerX], 4                   ; reset the player's x position

return_wall_collision:
    ret                                     ; return of the procedure

;; variables --------------------------------------------------------------------------------------------
playerY: dw 10                              ; starting y position for the player
playerX: dw 4                               ; starting x position for the player
playerSpeedX: db 0                          ; player x speed              
playerSpeedY: db 0                          ; player y speed
is_game_paused: db -1                       ; flag to notice if the game is paused
nombre: db 'Jason', 0

;; bootsector padding -----------------------------------------------------------------------------------
times 510-($-$$) db 0
	db 0x55
	db 0xaa
