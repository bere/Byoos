; This file is written for the NASM assembler

[BITS 16]	; Tell the assembler to use 16 bit mode
[ORG 0x7C00]	; The location where the BIOS will load our bootloader
				; Tell the assembler about that.


; Store Stack registers 
mov AX, SS
mov [orgSS], AX
mov AX, SP
mov [orgSP], AX


; Setup the stack, right before the current code position
; According to all documentation I found, this memory area should be free
mov AX, 0x0000
mov SS, AX
mov SP, 0x7C00

MOV SI, message
CALL printstring

MOV AX, [orgSS]
CALL printword

MOV AX, [orgSP]
CALL printword
   
MOV AX, SS
CALL printword

MOV AX, SP
CALL printword

JMP $			; endless loop			

;
; FUNCTION printstring
; * SI: Points to a zero terminated string
; 
printstring:
	PUSH AX
	PUSH BX
	MOV AH, 0x0E  	; CODE for print char
	MOV BX, 0x0007  ; Page #0 (highbyte), textattributes 07 (lightgrey on black)
_ps_next:
	MOV AL, [SI]
	OR AL, AL
	JZ _ps_finish
	INT 0x10		; BIOS Video interrupt

	INC SI
	JMP _ps_next

_ps_finish:
	
	POP BX
	POP AX

	RET 

;
; FUNCTION printword
; * AX: The word to print
;
printword:
	PUSH BX
	PUSH CX
	PUSH DX
	
	MOV CX, AX
	MOV AH, 0x0E	; CODE for print char
	MOV BX, 0x0007  ; Page #0 (highbyte), textattributes 07 (lightgrey on black)
	MOV DL, 4
	
.next:
	MOV AL, CH
	SHR AL, 4
	CMP AL, 0x0A
	JAE .hex
	ADD AL, '0'
	JMP .continue
.hex:
	ADD AL, 'A'-10
.continue:
	INT 0x10
	SHL CX, 4
	DEC DL
	JNZ .next
	
	POP DX
	POP CX
	POP BX
	
	RET		
		

; Data
message db 'Hello world', 0
orgSS 	dw	0
orgSP	dw	0

TIMES 510 - ($ - $$) db 0	; Set the remaining space of the first 510 bytes 
							; to 0
dw 0xAA55					; The last 2 bytes of the 512 byte block
							; mark it as a valid boot sector for the BIOS