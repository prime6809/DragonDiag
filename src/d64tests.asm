;
; Dragon 64 / Alpha only tests.
;

Dragon64Tests	
		ldb	#DIPMaskD64	; check if this is a Dragon64?
		lbsr	CheckMachine	; check against DIPS
		beq	Is64		; yep it's a 64

		ldb	#DIPMaskAlpha	; check if this is a Dragon Alpha?
		lbsr	CheckMachine	; check against DIPS
		bne	Not64		; Nope, not either

Is64		leax	MessD64,pcr	; Print D64 tests message
		lbsr	WriteStr	; write to screen
		
		leax	LMessD64,pcr	; Print D64 tests message
		lbsr	LCDClrWriteStrWait ; write to screen
		
		pshs	cc
		orcc	#IntsDisable	; disable interrupts

		sta	SAMCTY		; map type 0

; Configure PIA1 side b bit 2 as output and select second ROM	
		lda     PIA1CRB		; get control register of PIA1, port B
		anda    #~CRDDRDATA	; access DDR of port b
		sta     PIA1CRB		; update the PIA
	
		ldb     PIA1DB		; get DDR register
		orb     #MaskROMSEL	; make ROMSEL bit an output
		stb     PIA1DB		; write DDR
		ora     #CRDDRDATA	; access data register of port B
		sta     PIA1CRB		; tell PIA
	
		lda     PIA1DB		; get data register of PIA
		anda    #~MaskROMSEL	; select second ROM, containing code to be copied to RAM	
		sta     PIA1DB		; write it to PIA

		lbsr	ChecksumROMS	; do ROM checksums (RAM version)		

; switch ROMS back		
		lda     PIA1DB		; get data register of PIA
		ora    	#MaskROMSEL	; select first ROM
		sta     PIA1DB		; write it to PIA
					
		sta	SAMCP1		; back to page 0

		puls	cc		; restore int status 
		
		lbsr	LCDClrScr
		bsr	DumpACIA

		ldb	#DIPMaskAlpha	; check if this is a Dragon Alpha?
		lbsr	DIPMask		; check against DIPS
		cmpb	#DIPMaskAlpha
		bne	NotAlpha	; Nope, not Alpha
		
		leax	LPIA2Mess,pcr	; PIA2 message
		lbsr	DevWriteStr	; write it
		
		ldx	#PIA2DA		; point at PIA
		lbsr	GetPIADisplay2	; go display it
NotAlpha
		lbsr	WaitPause

		leax	LMessD64End,pcr	; Print D64 tests message
		lbsr	WriteStrUpper	

		leax	LMessD64End,pcr	; Print D64 tests message
		lbsr	LCDClrWriteStrWait ; write to screen
		
Not64		rts
	
;
; DumpACIA, dump ACIA registers to LCD/Screen
;	

DumpACIA	leax 	LACIAMess,pcr	; point at message
		lbsr	DevWriteStr	; write it

		ldu	#AciaData	; point at ACIA
		ldb	#4		; 4 bytes

DumpACIALoop	lda	,u+		; get byte from ACIA
		lbsr	DevHexByte	; display it
		cmpb	#1		; don't display dash after last byte
		beq	DumpACIANext	
		lbsr	DDash		; display dash
DumpACIANext	decb			; decrement count
		bne	DumpACIALoop	; loop again
		
		lbsr	DCR		; and EOL.
	
		rts
		

;
; Check if machine has 64K rams, if so test upper RAM
;		

RAM64Tests	lda	RAMFlag		; does this machinr have 64K RAMS?
		cmpa	#DRAM64
		bne	RAM64TestsExit	; no don't test upper RAM bank

		tst	IsCoCo3		; Is this a CoCo3?
		bne	RAM64TestsExit	; yes don't test upper RAM bank
		
		pshs	cc
		orcc	#IntsDisable	; disable interrupts

		inc	TestPage1	; flag to test we are doing page 1
		leax	LMess64K,pcr	; point to message
		lbsr	DoLongOrShort	; Do long test if enabled, else do short
		clr	TestPage1	; flag we are back to page 0

		puls	cc		; restore cc
RAM64TestsExit	rts
	