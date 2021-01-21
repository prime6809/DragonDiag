;
; Console related routines.
; 

TextMaxX	EQU	31		; Max X co-ordinate
TextMaxY	EQU	15		; Max Y co-ordinate
TextYMask	EQU	TextMaxX	; Mask to illiminate X bits
TextLastLine	EQU	(TextMaxX+1)*TextMaxY
VDGSpace	EQU	$60		; VDG space character


InitScreenVars	ldx	#TextScreenBase	; get base of screen RAM
		lbsr	SetSAMScr	; set SAM screen address

;
; Clear screen
;

ClearScreen	lda	#VDGSpace	; get space char
		ldx	ScreenBase	; point at screen base
		stx	CursorPos	; home cursor
CLSLoop		sta	,x+		; clear a character		
		cmpx	ScreenEnd	; end of screen
		bne	CLSLoop		; no keep going
		rts

;
; GotoXY
;
; Entry:
;	A	= New X
;	B	= New Y
; Exit:
;	Updates CursorPos, CC.C clear if ok, set if error in X or Y
;

GotoXY	cmpa	#TextMaxX		; validate X
	bhi	GotoXYError		; invalid, error
	
	cmpb	#TextMaxY		; validate Y
	bhi	GotoXYError		; invalid, error
	
	pshs	a			; save X
	lda	#(TextMaxX+1)		; chars / line
	mul				; multiply them
	addb	,s+			; add X
	adca	#0			; propagate carry
	addd	ScreenBase		; add screen base
	std	CursorPos		; update cursor position
	
	andcc	#~FlagCarry		; clear carry
	rts

GotoXYError	
	orcc	#FlagCarry		; flag error
	rts

;
; Move Cursor forward or backward the number of characters in b
;

CursorMove
	pshs	x			; save regs
	ldx	CursorPos		; get cursor pos
	leax	b,x			; move it
	stx	CursorPos
	puls	x,pc			; restor and return
	
;
; Write zero terminated string pointed to by X
;
		
WriteStr	lda	,x+		; get a char
		tsta			; test for end of string
		beq	WriteEnd	; yes exit	
		
		bsr	WriteChar	; Write it.
		bra	WriteStr	; do next char
		
WriteEnd	rts

;
; Write zero terminated string pointed to by X
;
		
WriteStrUpper	lda	,x+		; get a char
		tsta			; test for end of string
		beq	WriteEnd	; yes exit	
		
		lbsr	UpCase		; convert to upper case
		
WriteStrUpGo	bsr	WriteChar	; Write it.
		bra	WriteStrUpper	; do next char

;
; For convenience.......
;
VCR		lda	#CR		; EOL
		fcb	Skip2		; skip 2 bytes

VSpace		lda	#' '		; space character
		fcb	Skip2		; skip 2 bytes
		
VDash		lda	#'-'		; dash character
		fcb	Skip2		; skip 2 bytes
		
VDollar		lda	#'$'		; write a dollar char

WriteChar	tst	ScreenOK	; is it OK to use the screen
		bne	WriteCharOK	; yes....
		rts
		
WriteCharOK	pshs	d,x		; save regs
		ldx	CursorPos	; cursor positiion
		
		cmpa	#CR		; EOL?
		beq	WriteEol	; yes, deal with it
	
		cmpa	#BS		; backspace?
		bne	NotBS
	
		cmpx	ScreenBase	; at beginning of screen?
		beq	WriteCharEnd	; do nothing
		
		lda	#VDGSpace	; VDG space char
		sta	,-x		; backspace it
		bra	WriteCharDone	; save new cursor pos
		
NotBS		tsta			; set CC flags
		bmi	WriteCharGo	; just write it if semigraphic
				
		cmpa	#' '		; Is it a control char?
		blo	WriteCharEnd	; do nothing
		
		cmpa	#'@'		; is it a number or special char?
		bcs	WriteSpecial	; yes, go do it
		
		cmpa	#$60		; alphabetic uppercase?
		bcs	WriteCharGo	; yep write it
		
		anda    #$DF		; clear bit 5 force ASCII lower case to be upper
WriteSpecial	eora	#$40		; invert bit 6 swap upper / lower case 
WriteCharGo	sta	,x+		; write char to screen

		cmpx	ScreenEnd	; at end of screen?
		bne	WriteCharDone	; nope, we're done
		
		bsr	ScrollScreen	; scroll the screen....
		ldx	ScreenBase	; reset to beginning of last line
		leax	TextLastLine,x

WriteCharDone	stx	CursorPos	; resave cursor pos
WriteCharEnd	puls	d,x,pc		; restore and return		
		
WriteEol	stx	CursorPos	; save cursor pos
		bsr	ClrEOL		; clear to end of line
		bsr	Newline		; Move cursor to new line
		bra	WriteCharEnd	; restore cursor pos and continue

;
; WriteCharUpper, writes char but uppercase first....
;		
WriteCharUpper 	pshs	a		; save char so we don't change it
		lbsr	UpCase		; convert to upper case
		bsr	WriteChar	; go write it
		puls	a,pc		; restore and return
				
Newline		ldd	CursorPos	; get cursor pos
		andb	#~TextYMask	; 32 chars / line
		addd	#TextMaxX+1	; move to next line
		std	CursorPos	; save cursor pos
		cmpd	ScreenEnd	; are we past end of screen?
		blo	NewLineExit	; no, just return
		
		bsr	ScrollScreen	; else scroll screen
NewLineExit	rts

ScrollScreen	pshs	x,d		; save regs
		ldx	ScreenBase	; Base of screen
		leax	TextLastLine,x	; beginning of last line
		pshs	x		; save end on stack
		
		ldx	ScreenBase	; point at screen base
ScrollNext1	ldd	(TextMaxX+1),x	; get 2 chars from screen
		std	,x++		; save on line above
		cmpx	ScreenEnd	; end of screen?
		bne	ScrollNext1	; no, loop again

		puls	x		; restore end of last line pointer
		stx	CursorPos	; update cursor pos
		bsr	ClrEOL		; clear to end of line		
		
		puls	d,x,pc		; restore and return

VDGSet		pshs	a		; save a
		lda	OutputFlag	; get output flag
		sta	OldOutputFlag	; save it
		lda	#DevVDG		; LCD.....
		sta	OutputFlag	
		puls	a,pc		; restore and return

VHexByte	bsr	VDGSet		; set to LCD only
		lbsr	DevHexByte	; call hex routine
		lbra	OutputReset	; Reset output byte
		
VHexWord	bsr	VDGSet		; set to LCD only
		lbsr	DevHexWord	; call hex routine
		lbra	OutputReset	; Reset output byte
		
;
; Clear to end of cursor line. 
; Note does not change CursorPos
;
ClrEOL		pshs	x,d		; save regs
		ldd	CursorPos	; get cursor position
		andb	#~TextYMask	; 32 chars / line
		addd	#TextMaxX+1	; move to next line
		pshs	d		; save as target on stack
		lda	#VDGSpace	; get a space
		ldx	CursorPos
ClrEOLLoop	cmpx	,s		; reached EOL?
		beq	ClrEOLEnd	; yep exit
		sta	,x+		; clear a char
		bra	ClrEOLLoop	; do next 
		
ClrEOLEnd	leas	2,s		; drop new cursor pos
		puls	x,d,pc		; restore and return


;
; Save screen, copy screen RAM to temp buffer.
;

SaveScreen	ldx	ScreenBase	; get base of screen RAM
		ldy	#ScreenBuffer	; point to buffer to save in
SaveScreenLoop	lda	,x+		; get a byte
		sta	,y+		; save in buffer
		cmpx	ScreenEnd	; end of screen?
		bne	SaveScreenLoop	; nope keep going
		rts
		
RestoreScreen	ldx	ScreenBase	; get base of screen RAM
		ldy	#ScreenBuffer	; point to buffer to save in
RestoreScreenLoop	
		lda	,y+		; get a byte
		sta	,x+		; save in buffer
		cmpx	ScreenEnd	; end of screen?
		bne	RestoreScreenLoop ; nope keep going
		rts
