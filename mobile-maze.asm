[bits 16]                                   ; Tell nasm to assemble 16 bit code
[org 0x7C00]                                ; Tell nasm the code is running at boot sector

;; constants --------------------------------------------------------------------------------------------
KEY_W equ 0x11                              ; scancode for the W key                         
KEY_S equ 0x1F                              ; scancode for the S key
KEY_A equ 0x1E                              ; scancode for the A key
KEY_D equ 0x20                              ; scancode for the D key

;; set up video mode ------------------------------------------------------------------------------------
mov ax, 0x003                               ; Set video mode BIOS interrupt 0x10 AH = 0x00, AL = 0x03
int 0x10                                    ; systemcall

; set up video memory -----------------------------------------------------------------------------------
mov ax, 0xB800
mov es, ax 


;; game loop for the game renderization -----------------------------------------------------------------
game_loop:
    ; clear the screen with black
    xor ax, ax                              ; clear the AX register
    xor di, di                              ; clear the DI register
    mov cx, 80*25                           ; set up the number of repetitions
    rep stosw                               ; put AX into [es:di] and increment DI

    ; print the name label
    mov si, nombreD
    mov di, 1*2
    call video_string

    ; configure the draw wall's common values to save memory space
    mov ah, 0x30                            ; character config: bg -> 0, fg -> F, char -> 0

    ; Draw V wall # 1          
    mov bx, 40                              ; starting x position
    mov dx, 1                               ; starting y position
    mov cl, 10                              ; wall length
    call draw_wall                          ; draw the wall

    ;Draw V wall # 2
    mov bx, 40                              ; starting x position
    mov dx, 14                              ; starting y position
    mov cl, 11                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 3
    mov bx, 100                             ; starting x position
    mov dx, 3                               ; starting y position
    mov cl, 22                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw V wall # 4
    mov bx, 156                             ; starting x position
    mov dx, 0                               ; starting y position
    mov cl, 23                              ; wall length
    call draw_wall                          ; draw the wall

    ; Draw the player on screen
    mov ah, 0x0F0                           ; character config: bg -> 0, fg -> F, char -> 0
    imul di, [playerY], 160                                     
    add di, [playerX]
    stosw
    stosw
    add di, 2*80-4


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

    ;; Move the player
    move_player:
        mov bl, [playerSpeedX]               ; laod the X speed into BL register
        add [playerX], bl                    ; add the X speed to the player X position
        
        mov bl, [playerSpeedY]               ; load the Y speed into BL register
        add [playerY], bl                    ; add the Y speed to the player Y position

    ;; check top collision
    check_top_collision:
        cmp word [playerY], 1                ; compare player Y position with 1
        jg check_bottom_collision            ; if player Y position is greater than 1, continue the check
        neg byte [playerSpeedY]              ; otherwise, invert the player Y direction

    ;; check bottom collision
    check_bottom_collision:
        cmp word [playerY], 24               ; compare player Y position with 24
        jl check_left_collision              ; if player Y position is less than 24, continue the check
        neg byte [playerSpeedY]              ; otherwise, invert the player Y direction

    ;; check left collision
    check_left_collision:
        cmp word [playerX], 2                ; compare player X position with 2
        jg check_right_collision             ; if player X position is greater than 2, continue the check
        mov byte [playerSpeedX], 4           ; otherwise, invert the player X direction

    ;; check right collision
    ;; This is the winning level checkpoint
    check_right_collision:
        cmp word [playerX], 154              ; compare player X position with 2
        jl check_walls_collision             ; if player X position is less than 154, continue to game_tick
        mov byte [playerSpeedX], -4          ; otherwise, invert the player X direction


;; procedure to check collision with a specific wallW
;; providing the wall x position, y position, and wall length
;; AL register: 1 is the wall is up, 0 is wall is down
;; BX register: The wall x position
;; Cx register: The wall length

check_walls_collision:
    ;; check collision with V wall # 1
    mov al, 1
    mov bx, 40
    mov cx, 11-1
    call wall_collision_stage_1

    ;; check collision with V wall # 2
    mov al, 0
    mov bx, 40
    mov cx, 14
    call wall_collision_stage_1

    ;; check collision with V wall # 3
    mov al, 0
    mov bx, 100
    mov cx, 3
    call wall_collision_stage_1

    ;; check collision with V wall # 4
    mov al, 1
    mov bx, 156
    mov cx, 23-1
    call wall_collision_stage_1

;; game delay time before rendering the screen's content again
game_tick:
    mov bx, [0x046C]
    inc bx
    inc bx
    .delay:
        cmp [0x046C], bx
        jl .delay

jmp game_loop                                ; repeat the game loop                 
;; end of game loop --------------------------------------------------------------------------------------

;; Video string procedure --------------------------------------------------------------------------------
;; arguments: SI register, DI register
;; SI register: The pointer to the string starting address
;; DI register: The place (times 2 bytes) where you want to start placing the first char on screen 
video_string:
    xor ax, ax                               ; AX = zero     
    lodsb                                    ; put the charcter from SI into AL              
    cmp al, 0                                ; is the current char the end of the string????             
    je .return                               ; if true, then return     
    mov ah, 0x0F                             ; otherwise, set up the character set up
    stosw                                    ; put AX into [es:di] and increment DI                                    
    jmp video_string                         ; continue with the next char from the string                      
.return: ret                                 ; return from procedure             


;; Draw wall procedure -----------------------------------------------------------------------------------
;; arguments: AH register, BH register, DX register, CH register
;; AH register: The charcter config --> bg:fg:char
;; BX register: The wall x position
;; DX register: The wall y position
;; CL register: The wall length
draw_wall:
    imul di, dx, 160                             
    add di, bx
    .draw_wall_loop:
        stosw
        stosw
        add di, 2*80-4
        loop .draw_wall_loop
ret


;; wall collision procedure ------------------------------------------------------------------------------
;; providing the wall x position, y position, and wall length
;; AL register: 1 is the wall is up, 0 is wall is down
;; BX register: The wall x position
;; CX register: wall y position if AL is 0, wall (y position + length - 1) if AL is 1
wall_collision_stage_1:
    cmp word [playerX], bx                  ; player x position is the same as wall x position
    je  wall_collision_stage_2              ; go check if player y is on the wall's y position range
    jmp return_wall_collision               ; if not, return from the procedure

wall_collision_stage_2:
    cmp al, 1                               ; is the wall above??
    je  wall_collision_upY                  ; check up condition

wall_collision_downY:
    cmp word [playerY], cx                  ; compare the player y position with the wall length
    jl return_wall_collision                ; if player is above the wall's y position, then return
    jmp kill_player                         ; otherwise, game over               

wall_collision_upY:
    cmp word [playerY], cx                  ; compare the player y position with the wall length
    jg  return_wall_collision               ; if player is under the wall's y position, then return

kill_player:
    mov byte [playerSpeedX], 0              ; disable player speed
    mov byte [playerX], 4                   ; reset the player's x position

return_wall_collision:
    ret                                     ; return of the procedure


;; variables --------------------------------------------------------------------------------------------
playerY: dw 10                               ; starting y position for the player
playerX: dw 4                                ; starting x position for the player
playerSpeedX: db 0
playerSpeedY: db 0

nombreD: db 'Nombre: ', 0
nombre: db 'Jason', 0

;; bootsector padding -----------------------------------------------------------------------------------
times 510 - ($ - $$) db 0       ; fill trainling zeros to get exactly 512 bytes long binary file
dw 0xAA55                       ; set boot signature
