[BITS 16]
[ORG 0x7C00]

; demo. reads bootsector into ram
; assemble with
;		nasm bootstrap.asm -fbin
; inject into bootsector of a hd image using injectbl from tools
; 		./injectbl bootstrap image.img 0

print_bootmsg:
	call 	cls
	mov 	ax,msg_check
	call 	printsz


load_sector:
	; just messing with int 13h
	mov ax, 0x10		;DAP size = 16 bytes				[Byte]   0x10
	mov [0x0500],ax		;reserved byte zero					[Byte]   0x00
	
	mov	ax,0x01			;read one block						[Word] 0x0001
	mov [0x0502],ax		;
				
	xor ax,ax			; offset							[Word] 0x0000
	mov [0x0504],ax		;
	mov ax,0x7E0		;read to 0x7E00	(0x7E * 0x10)		[Word] 0x07E0
	mov [0x0506],ax		;	
	
	xor ax,ax			; start at block number 0
	mov	[0x0508],ax		;									[Word] 0x0000
	mov	[0x050A],ax		;									[Word] 0x0000
	mov	[0x050C],ax		;									[Word] 0x0000
	mov	[0x050E],ax		;									[Word] 0x0000
	 

	push ds				; push data segment to retain value
	
	mov ax, 0x0050		;0x50 * 0x10 = 0x500
	mov ds,ax			;using dap at 0x500
	
	xor si,si			;offset 0
	mov dl, 0x80		;from hd0
	mov	ah, 0x42		;extended read
	
	int 0x13
	
	pop ds			 	
		
	
	jc ioerror
	
	mov 	ax,msg_lddone
	call 	printsz
			
hang:
	jmp hang
		
ioerror:
	mov  ax,msg_error
	call printsz
	jmp hang
	
	
; print string in ax (will change ax)
printsz:
		push	bx
		push	si
		
		mov		si,ax
		
        mov     ah, 0x0e        ; Teletype output
        mov     bl, 0x07        ; text mode = light grey foreground

.loop:
		mov		al,[si]
        or     	al,al			
        jz      .done           ; Exit on \0
        int     0x10            ; print the character
		inc		si				; 
        jmp     .loop           ; start over
.done:
		pop 	si
		pop		bx
        ret

;clear screen / set mode
cls:
		push	ax
		xor		ah,ah
		mov		al,0x03
		int		0x10
		pop		ax
		ret
		

;Messages
msg_check:	db      'Booting...',0x0a,0x0d,0x0
msg_error:	db		'I/O Error' ,0x0a,0x0d,0x0
msg_lddone: db		'Loading done',0x0a,0x0d,0x0
					
