;
; CoCo 3 specific tests.
;

;DefaultInit1	EQU	#Init1CoCo+Innit1MMU+Init1GIRQ	
DefaultInit1	EQU	Init1CoCo+Init1MMU
;+Init1GIRQ	


		ifndef Test
DPOffset	EQU	$80		; Offset of new DP from current
RAMOffset	EQU	DPOffset*256	; Offset to routines copied to RAM
StackOffset	EQU	RAMOffset		
		else
DPOffset	EQU	$00		; Offset of new DP from current
RAMOffset	EQU	$8000		; Offset to routines copied to RAM
StackOffset	EQU	$2000
		endc
		
CoCo3Tests
	tst	IsCoCo3			; is this machine a coco3 ?
	beq	CoCo3TestsExit		; nope, exit

	lbsr	ChecksumCC3		; Checksum ROMS
	
	bsr	CoCo3RAM		; CoCo3 RAM test	

CoCo3TestsExit
	rts

CoCo3RAM
	orcc	#IntsDisable		; disable interrupts
	clr	SAMSR2			; 2MHz mode for RAM test!
	
	lbsr	GetTestLength		; Get and set test length
	bsr	GetCoCo3RamSize		; Get minimum bank number
	
	com	CoCo3Blocks		; Flag that we are testing blocks
	
	lda	MMUT0Block2		; get current block 2 and save it
	sta	CoCo3SaveBlock2
	
	lda	MMUT0Block4		; get current block 4 and save it
	sta	CoCo3SaveBlock4
	

	lda	CoCo3MinBank		; Get start block
CoCo3RAMLoop
	sta	MMUT0Block2		; map it in
	sta	CoCo3BlockNo		; Tell display procedure
	
	leax	BlockRange,pcr		; point at address table
	lbsr	DoRamTest		; go test the RAM
	bne	CoCo3RAMExit		; failure, exit
	
	lda	MMUT0Block2		; move to next bank
	anda	#BlockNoMask		; Mask out invalid bits
	inca				
	cmpa	#MaxBlockRRMode		; > max block with ROM paged in?
	ble	CoCo3RAMLoop		; no keep going

; We have reached the maximum block number we can test with the ROMS enabled as blocks
; $3C-$3F will be mapped to the ROM and not RAM!
; Now that we have tested the lower blocks, we can copy ourselves to lower RAM
; page the roms out and continue testing from there.....

	lda	CoCo3SaveBlock2		; restore mapped block 2
	sta	MMUT0Block2

	lda	#MaxBlockRRMode+1	; Start block
	sta	CoCo3MinBank		; save it for later

	lbsr	CoCo3RAMCopy		; copy us to RAM
	
	leax	CoCo3RAMTestRAM,pcr	; point to continued test
	jsr	CoCo3RAMCallX		; call it
	
	
CoCo3RAMExit
	lda	CoCo3SaveBlock2		; restore mapped block 2
	sta	MMUT0Block2

	lda	CoCo3SaveBlock4		; restore mapped block 2
	sta	MMUT0Block4

	clr	CoCo3Blocks		; Flag normal RAM test
	andcc	#IntsEnable		; renable interrupts
	rts

CoCo3RAMTestRAM	
	clr	SAMSTY			; all RAM mode....

; We have to get and set the test routine address, as the old ROM based
; address will still be stored there.....	
	lbsr	GetTestLength		; Get and set test length
	lda	CoCo3MinBank		; Get start block
CoCo3RAMLoop2
	sta	MMUT0Block4		; map it in
	sta	CoCo3BlockNo		; Tell display procedure
	
	leax	BlockRange2,pcr		; point at address table
	lbsr	DoRamTest		; go test the RAM
	bne	CoCo3RAMExit2		; failure, exit
	
	lda	MMUT0Block4		; move to next bank
	anda	#BlockNoMask		; Mask out invalid bits
	inca				
	cmpa	#MaxBlock		; > max block 
	ble	CoCo3RAMLoop2		; no keep going
		
CoCo3RAMExit2
	clr	SAMCTY			; RAM / ROM mode....
	rts
	
BlockRange
	FDB	Block2Base,Block3Base	; Area of memory with block mapped in
BlockRange2
	FDB	Block4Base,Block5Base	; Area of memory with block mapped in, upper blocks

; Work out the Size of the RAM (128K or 512K), by checking for RAM 
; mirroring.	
TestWord	EQU	$6809		; test word for mirror check

GetCoCo3RamSize	
	ldd	MMUT0Block2		; save current mappings
	pshs	d
	
	lda	#MinBlock128		; Get minimum block number for 128K machine
	sta	CoCo3MinBank		; assume we only have 128K
	
	sta	MMUT0Block2		; Map block in.
	suba	#$10			; Block no of mirror (if 128K)
	sta	MMUT0Block3		; Map block in
	
	clr	Block3Base		; clear first word of mirror block
	clr	Block3Base+1		
	
	ldd	#TestWord		; get test word
	std	Block2Base		; save it in block
	cmpd	Block3Base		; is it mirrored?
	beq	RestoreMap		; yes, leave machine as 128K
	
Set512K	lda	#MinBlock512		; min block for 512K
	sta	CoCo3MinBank		; set it

RestoreMap	
	puls	d			; restore mappings
	std	MMUT0Block2
	rts
	
CoCo3GIMERegs
	rts

;
; Checksum 'hiddern' ROMS at $C000 and $E000
;
ChecksumCC3
	bsr	CoCo3RAMCopy		; copy us to RAM
	leax	ChecksumCoCo3,pcr	; Point to routine
	bsr	CoCo3RAMCallX		; call copy in RAM
	rts

ChecksumCoCo3
	lda	StatusReg		; Set disable bit in Diag status reg
	ora	#StatusDisable
	sta	StatusReg
	
	lda	#DefaultInit1		; Setup mapping of RAM
	anda	#~Init1ROMMask		; mask out any existing ROM bits
	ora	#IntitROMInt		; 32K internal ROM
	sta	InitReg1		; map it!
	
	lbsr	LCDClrScr		; Clear LCD screen
		
	leax	LMessCSumC0,pcr		; point to LCD message
	lbsr	DevWriteStr		; write it to LCD
	
	ldu	#$C000			; first rom $C000-$DFFF
	ldy	#$E000
	lbsr	ChecksumROM		; go get checksum
		
	inc	LEDS
		
	leax	LMessCSumE0,pcr		; point to LCD message
	lbsr	DevWriteStr		; write it to LCD

	ldu	#$E000			; second rom $E000-$FDFF
	ldy	#$FE00
	lbsr	ChecksumROM		; go do checksum

	inc	LEDS
	lbsr	Newline			; and newline

;	ldb	#2			; double length delay
;	lbsr	WaitBPause		; Wait for user to read results
	rts
	
CoCo3RAMCopy
	pshs	cc			; save flags
	ora	#IntsDisable
	lda	#DefaultInit1		; Setup Default mode, RAM/ROM mode
	sta	InitReg1
	
	ldx	#CartBase		; base of our RAM
	leay	-RAMOffset,x		; dest 32K lower
	
CoCo3RAMCopyLoop
	ldd	,x++			; get a word from ROM
	std	,y++			; save in RAM
	cmpx	#$FF00			; done all
	blo	CoCo3RAMCopyLoop	; no keep going
	
	puls	cc,pc			; restore and return

;
; Copy vars back after call.
;

CoCo3CopyVars
	ldx	#RAMBase		; point at RAM base
	leay	-RAMOffset,x		; point at copy in lower RAM

CoCo3CopyVarsLoop
	lda	,y+			; get a byte from lower RAM
	sta	,x+			; save in vars
	cmpx	#RamEnd			; done all?
	bne	CoCo3CopyVarsLoop	; nope loop again
	rts
	

;
; Call a routine in RAM copy of code, routine in ROM supplied in X
; X is adjusted for correct address in RAM before calling.
; DP and S are also adjusted to ROMS may be paged out.
;
; This routine should be entered as a subroutine with JSR/BSR/LBSR.
;	
CoCo3RAMCallX	
	pshs	cc,dp			; save current CC & DP
	ora	#IntsDisable		; disable interrupts
	
	sts	>SavedS			; save current stack pointer
	leas	-StackOffset,s		; Point S at CoCo RAM
	pshs	a			; save a
	tfr	dp,a			; get DP
	suba	#DPOffset		; adjust DP to point to RAM
	tfr	a,dp			; set DP
	puls	a			; restore a
	
	leax	-RAMOffset,x		; Point at address in RAM
	pshs	x			; save address to call on stack
	leax	CoCo3RAMCall2,pcr	; Get our address in RAM
	leax	-RAMOffset,x		; Adjust for RAM
	jmp	,x			; call RAM routine

; this is executed in RAM
CoCo3RAMCall2
	puls	x			; restore X
	jsr	,x			; call routine

; routine will return here, still in RAM	
CoCo3RAMReturn
	lda	#DefaultInit1		; back to RAM/ROM mode
	sta	InitReg1
	
	lda	StatusReg		; reset disable bit in status reg
	anda	#~StatusDisable
	sta	StatusReg		; store it back
	
	lds	>SavedS			; restore stack pointer
	puls	cc,dp			; restore DP & CC
	bsr	CoCo3CopyVars		; copy vars back
	rts				; return to caller