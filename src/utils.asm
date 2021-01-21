Wait		ldb	#$02	
WaitB		tst	NoWait		; are we waiting?
		bne	WaitExit	; nope exit
	
WaitLoop2	ldx	#$0000		; zero counter
WaitLoop	leax	-1,x		; decrement inner count
		bne	WaitLoop	; loop until zero
		
		decb			; decrement outer counter
		bne	WaitLoop2	; loop until zero
WaitExit	rts


WaitPause	pshs	cc		; save codes
		ldb	#$01	
		fcb	Skip2

WaitBPause	pshs	cc
WaitBPause2	tst	NoWait		; are we waiting?
		bne	EndWait		; nope exit

WaitPauseLoop2	ldx	#$0000		; zero counter
WaitPauseLoop	lbsr	CheckPause	; check for Pause press
		leax	-1,x		; decrement inner count
		bne	WaitPauseLoop	; loop until zero
		
		decb			; decrement outer counter
		bne	WaitPauseLoop2	; loop until zero

WaitUnPause	tst	Paused		; is pause pressed?	
		beq	EndWait		; no, exit
		lbsr	CheckPause	; check for Pause press
		bra	WaitUnPause
		
EndWait		puls	cc,pc		; restore and return

;
; UpCase, convert character in A to upper case
;

UpCase		cmpa	#'a'		; lowercase A
		blo	UpCaseExit	; lower leave it alone
		
		cmpa	#'z'		; lower case z
		bhi	UpCaseExit	; higher leave it alone
		
		anda	#$DF		; force it upper case
UpCaseExit
		rts

;
; HexByte, HexWord. Write Hex byte in A or hex word in D to buffer at X
;
; On exit X contains the updated buffer pos.
;

BufHexByte	pshs	a		; save byte
		anda	#$F0		; get MSN
		lsra			; shift to LSN
		lsra	
		lsra
		lsra			
		bsr	HexNibble
		lda	,s		; recover value
		anda	#$0F		; Mask oust LSN
		bsr	HexNibble
		clr	,x		; zero terminator
		puls	a,pc		; restore and return
		
HexNibble	adda	#'0'		; convert to ASCII
		cmpa	#'9'		; is it A..F?
		bls	OutHexNibble	; no output it
		adda	#'A'-':'	; add difference
OutHexNibble	sta	,x+		; go write it in buffer
		rts

BufHexWord	pshs	d		; save word
		bsr	BufHexByte	; output msb
		lda	1,s		; get LSB
		bsr	BufHexByte	; output msb
		puls	d,pc		; restore and return
		
		
;
; CR on VDG, and clear LCD screen
; 		
VCRLCDClrScr	lbsr	VCR		; CR on VDG screen
		lbra	LCDClrScr	; clear LCD
		
VCRLCDClrMess	pshs	x		; save message pointer
		lbsr	VCR		; CR on VDG screen
		lbsr	LCDClrScr	; clear LCD
		puls	x		; restore pointer
		lbra	DevWriteStr	; output it
;		lbra	LCDNewLine	; and move to a newline on LCD