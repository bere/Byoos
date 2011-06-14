; demo. reads bootsector into ram
; assemble with
;		nasm bootstrap.asm -fbin
; inject into bootsector of a hd image using injectbl from tools
; 		./injectbl bootstrap image.img 0

[BITS 16]
[ORG 0x7C00]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									MACROS	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DAP structure for reading params (int 0x13)
%define 	DAP_START	0x0500
struc		tDAP
			.SIZE			RESB	1
			.RESERVED		RESB	1
			.READ_BLOCKS	RESW	1
			.TO_OFFSET		RESW	1
			.TO_SEGMENT		RESW	1
			.START_BLOCK	RESQ	1
endstruc
%define	DAP(x)	DAP_START + tDAP. %+ x

; int 0x10 defines
%define VIDEOMODE 0x03		;80x25 16 colors
%define TTY 0x0e 			;teletype mode

; int 0x13 defines
%define HD 0x80				; hd0
%define	EXTENDED_READ 0x42


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									MAIN	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	call 	cls
	
	; print boot message
	push	msg_check
	call 	printsz
	add		sp,2				;reset stack pointer (2 bytes pushed)
	
	
	;load boot sector to 0x7E00
	push	0x0000				;start read at block number
	push	0x0000				;assuming the stack in 16bit mode is only 16bits wide
	push	0x0000				;
	push	0x0000				;
	
	push	0x07E0				;read to segment 0x07E0
	push	0x0000				;read to offset 0		 (= mem addr 0x7E00)	
		
	push	0x0001				;read 1 block
	
	call	load				;cleaning up later (add changes carry flag)------v 
	
	jnc 	cont				;check for errors
	push	msg_error			;and complain if there were any
	call 	printsz
	add		sp,2				;reset stack pointer (2 bytes pushed)
cont
	add		sp,14				;;reset stack pointer (2 bytes pushed) ----------^  	
	
	push 	msg_done
	call	printsz
	add		sp,2
	
hang:
	jmp hang					;hang


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									FUNCTIONS	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read from hd0
; parameters:
;				W	number of blocks
;				W	read to offset
;				W	read to segment
;				QW	start at block number (push words hi to lo)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load:

	push 	bp
	mov		bp,sp
	
	push 	ds
	push 	si
	
	push 	ax
	push 	bx
	
	; prepare DAP
	mov	 	ax, 0x10				;DAP size = 16 bytes	[Byte]   0x10
	mov 	[DAP(SIZE)],ax			;reserved byte 			[Byte]   0x00
	
	mov		ax,[4+bp]				;no. of blocks to read	[Word] 
	mov 	[DAP(READ_BLOCKS)],ax	;
				
	mov 	ax,[6+bp]				;offset					[WORD]
	mov 	[DAP(TO_OFFSET)],ax		;
	mov 	ax,[8+bp]				;segment				[WORD]
	mov 	[DAP(TO_SEGMENT)],ax	;	
	
	mov 	ax,[10+bp]				; start at block		[QWORD]
	mov		[DAP(START_BLOCK)],ax
	mov 	ax,[12+bp]
	mov		[DAP(START_BLOCK)+2],ax
	mov 	ax,[14+bp]
	mov		[DAP(START_BLOCK)+4],ax
	mov 	ax,[16+bp]
	mov		[DAP(START_BLOCK)+6],ax
	 
	; call interrupt
	mov ax, (DAP_START/0x10)		;
	mov ds,ax						;using dap at given address		
	xor si,si						;offset = 0

	mov dl, HD						;
	mov	ah, EXTENDED_READ
	
	int 0x13
		
.done
	pop bx
	pop ax
	pop si
	pop ds

	pop bp
	ret	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; prints zero terminated string
; parameters:
;				W	pointer to string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
printsz:
	
	push 	bp
	mov		bp,sp
	
	push	si
	push 	ax
	
	mov		si,[4+bp]
	mov     ah, TTY
		
.loop:
	mov		al,[si]
    or     	al,al			
    jz      .done           	; Exit on \0
    int     0x10	            ; print the character
	inc		si					; 
    jmp     .loop       	    ; start over
.done:
	pop		ax
	pop 	si
	
	pop		bp
	ret
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;clear screen / set mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cls:
		push	ax
		xor		ah,ah				;set video mode
		mov		al,VIDEOMODE
		int		0x10
		pop		ax
		ret
		


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;									DATA	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
msg_check:	db      'Booting...',0x0a,0x0d,0x0
msg_error:	db		'I/O Error' ,0x0a,0x0d,0x0
msg_done: 	db		'Loading done',0x0a,0x0d,0x0
					
