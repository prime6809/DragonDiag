;
; OutDev, combined VDG / LCD output
;

;
; LCD hex routines
;

DevHexByte	pshs	d,x		; save regs
		leax	PrintBuff,pcr	; point at print buffer 
		lbsr	BufHexByte	; put it in buffer
DHexPrint	bsr	DevPrintBuff	; print it from buffer
		puls	d,x,pc		; restore and return

DevHexWord	pshs	d,x		; save regs
		leax	PrintBuff,pcr	; point at print buffer 
		lbsr	BufHexWord	; put it in buffer
		bra	DHexPrint	; print it

DevPrintBuff	pshs	x,a		; save x
		leax	PrintBuff,pcr	; point at print buffer 
		lbsr	DevWriteStr	; go write it
		puls	a,x,pc		; restore and return


;
; DevWriteStr, write a zero terminates string from X
;

DevWriteStr	pshs	a		; save a
DevWriteStrLoop	lda	,x+		; get character from string
		beq	DevWriteStrExit	; exit if null
		
		bsr	DevWriteChar	; write it
		bra	DevWriteStrLoop	; write next

DevWriteStrExit	puls	a,pc		; restore and return

DevWriteStrWait	
		bsr	DevWriteStr	; clear screen, write string
		lbra	WaitPause	; and then wait

;
; Write a specified number of characters.
;		
; Entry:
;	X	= address of string to write
;	B	= character count
;

DevWriteStrN	
	tstb				; end of string?
	beq	DevWriteEnd		; yes exit	
	lda	,x+			; get a char
		
	bsr	DevWriteChar		; Write it.
	decb
	bra	DevWriteStrN		; do next char
DevWriteEnd
	rts


;
; For convenience.......
;
DCR		lda	#CR		; carrage return
		fcb	Skip2		; skip 2 bytes
		
DSpace		lda	#' '		; space character
		fcb	Skip2		; skip 2 bytes
		
DDash		lda	#'-'		; dash character
		fcb	Skip2		; skip 2 bytes
		
DDollar		lda	#'$'		; write a dollar char

;
; Write character in A to devices in OutputFlag.
;
		
DevWriteChar	pshs	b		; save b

		ldb	#DevVDG		; output to VDG?
		bitb	OutputFlag		
		beq	DW1		; nope skip
		lbsr	WriteCharUpper	;  write to VDG
		
DW1		ldb	#DevLCD		; output to LCD?
		bitb	OutputFlag		
		beq	DW2		; nope skip
		lbsr	LCDWriteChar	; write to LCD		
DW2		
		puls	b,pc		; restore and return

;
; Output reset
;

OutputReset	pshs	a		; save register
		lda	OldOutputFlag	; restore old output
		sta	OutputFlag	
		puls	a,pc		; resore and return