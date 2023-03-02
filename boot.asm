bits 16   		  	; As we are running in safe mode, we have to work at 16 bits
org 0x7c00		  	; Set the offset at the BIOS starting location

boot:
	cli  		  	; Disable interruptions
	mov si, message	  	; Point SI register to message
	mov ah, 0x0e  	  	; Set higher bits to the display character command
	sti		  	; Enable interruptions

messageProcessing:
	lodsb     	  	; Load the character within the AL register, and increment SI
	cmp al, 0 	  	; Is the AL register a null byte?
	je stop     	  	; Jump to halt
	int 0x10  	  	; Trigger video services interrupt
	jmp messageProcessing 	; Loop again

stop:
	hlt         	  	; Stop

message:
	db "Wenas wenas!", 0	; Message to display

; Set as booteable
times 510-($-$$) db 0 	  	; Set 0 to left values 
	db 0x55			; Write the last 2 bytes at 0xaa and 0x55
	db 0xaa 		; Write the last 2 bytes at 0xaa and 0x55
times (1440 * 1024)-($-$$) db 0 ; Set 0 to left values 
