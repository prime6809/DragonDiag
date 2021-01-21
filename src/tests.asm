;
; Test routines for Diag cart.
;

;
; Quick RAM tests, just values $FF and $00
;

DoQuickTest	leau	QRamTest,pcr	; point to short test
		stu	TestVector	; set the test vector
GoTestRAM	leax	RamBanksSmall,pcr	; assume 4K
		tst	RAMFlag		; are we configured for 4K rams?
		beq	SetBanks	; yes use them
		
		leax	BankTableSize,x	; select large table

SetBanks	bsr	DoRamTest	; test first bank
		
		inc	LEDS

		ldb	RAMFlag		; Check RAM size
		cmpb	#DRAM64		; Check to see if we have 4K or 16K RAMS
		bhs	Rams64		; yes we do both banks as same chips
		
		ldb	#DIPOneBank	; just do one bank?
		lbsr	DIPMask		; test it
		bne	JustOne		; yes, skip second

Rams64		leax	4,x		; next table entry
		bsr	DoRamTest	; test second bank
JustOne		inc	LEDS
NoLongTests	rts


;
; Long RAM tests, test blocks, with all 255 values.
;
; on entry X points to a string to be displayed before beginning the tests.

DoLongTest	ldb	#DIPSkipLong	; skip long tests?
		lbsr	DIPMask		; check against DIPS
		bne	NoLongTests	; yes skip them

		tst	IsCoCo3		; Is this machine a CoCo3?
		bne	NoLongTests	; yes skip them, we will do specific test later

DoLong		leau	LRamTest,pcr	; point to long test
		stu	TestVector	; set the test vector
		
DoTests		lbsr	VCRLCDClrScr	; Clear LCD display, CR on VDG
		lbsr	DevWriteStr	; display it
		lbsr	WaitPause	; delay a little
		
		bra	GoTestRAM

;
; Do long or short test dependent on dip.
;
; on entry X points to a string to be displayed before beginning the tests.

DoLongOrShort	bsr	GetTestLength	; Set test length
		bra	DoTests		; go do it

;
; GetTestLength, returns the test type to perform in U.
; Checks the SkipLong DIP switch and if set returns a pointer to 
; the short test, otherwise a pointer to the long test.
;

GetTestLength	ldb	#DIPSkipLong	; skip long tests?
		lbsr	DIPMask		; check against DIPS
		bne	DoShortTest	; only do short test
		
		leau	LRamTest,pcr	; point to long test	
		bra	SetTestVec	

DoShortTest	leau	QRamTest,pcr	; point to short test	
SetTestVec	stu	TestVector	; set the test vector
		rts
		
;
; RAM tests, outputting to VDG and LCD.
;
; Entry :
; 	X 		= pointer to table of start, end address
;	TestVector	= address of test routine to run
; Exit
;	CC.Z	= set on error
;

DoRamTest	pshs	u,x

		tst	CoCo3Blocks	; Are we processing CoCo 3 RAM blocks?
		bne	ShowBlocks	; yes display for blocks
		
		pshs	x
		lbsr	LCDClrScr	; clear LCD screen.
		leax	LMessRamTest,pcr ; point to message
		lbsr	DevWriteStr
		
		puls	x
		
		ldd	,x		; print start address
		
		lbsr	DevHexWord		
		
		lbsr	DDash		; output dash, then dollar
		lbsr	DDollar		; 
		
		ldd	2,x		; print end address
		lbsr	DevHexWord
		bra	DoRamTest2	; do rest of test
	
ShowBlocks	pshs	x
		lbsr	LCDClrScr	; clear LCD screen.
		leax	LMessRamTestB,pcr ; point to message
		lbsr	DevWriteStr
	
		puls	x

		lda	CoCo3BlockNo	; get current block no
		anda	#BlockNoMask	; Mask out invalid bits
		lbsr	DevHexByte	; display it
		
DoRamTest2
		lbsr	DSpace		; print a space

		ldy	2,x		; get test addresses from table
		ldx	,x
		
		clr	TestContinue	; Flag beginning of RAM test
		
; not we cannot use indirect jsr [TestVector] as this gets assembled as the
; absolute 16 bit address of TestVector, we need the DP relative version.
		
RestartTest	ldu	TestVector	; run ram test	
		jsr	,u
		bne	RamTestFailed
		
		bsr	RAMPassed	; Display passed message
		bra	RamTestExit	; restore and exit	
		
RamTestFailed	bsr	RAMFail		; do ram fail output
		bne	RamTestExit	; next pressed, exit test
		clra	
		coma			; flag test to continue
		sta	TestContinue
		bra	RestartTest	; restart it....
		
RamTestExit	puls	u,x,pc		; restore and return

RAMPassed	leax	MessPassed,pcr	; Passed message
		lbsr	WriteStr
		
		leax	LPassed,pcr	; Passed message
		lbsr	LCDWriteStr
		
		lbra	WaitPause	; give user time to see it....

	
RAMFail		leax	MessFailedAt,pcr ; print failed message
		lbsr	WriteStr
		
		ldd	#$0001		; column 12 line 2
		lbsr	LCDGotoXY	; go to co-ordinates

		leax	LMessFailedAt,pcr	; point to fail message
		lbsr	LCDWriteStr	; write it to LCD
		
		ldd	TestFailAddr	; get address of first failure
		lbsr	DevHexWord	; display it
		
		lbsr	LSpace		; output a space
		
		leax	MessWrote,pcr	; Display byte written
		lbsr	WriteStr
		
		lda	#'w'		; wrote byte
		lbsr	LCDWriteChar	; write it
		
		lda	TestWrote	; get byte written
		lbsr	DevHexByte
		
		leax	MessRead,pcr	; Display byte read
		lbsr	WriteStr
		
		lbsr	LSpace		; output a space
		lda	#'r'		; wrote byte
		lbsr	LCDWriteChar	; write it

		lda	TestRead	; get byte read
		lbsr	DevHexByte
		
		lbsr	Newline		; print an EOL

RamFailWait	lbsr	QueryButton	; wait for button press

		cmpa	#ButtonNext	; Was next pressed?
		beq	FlagTerminate	; yes, flag terminate
		
		cmpa	#ButtonSkip	; Was it skip
		beq	RamFailExit	; yes flag skip...zero flag already set
		bra	RamFailWait	; neither wait for a valid button.....
		
FlagTerminate	andcc	#~FlagZero	; Flag, next so terminate
		
RamFailExit	rts

; If running in test mode im MAME, don't test the RAM we are using.....
		ifdef Test
FirstRam	equ	RAMTop+1
		else
FirstRam	equ	$0000
		endc	

; RAM banks if using 4K RAMS
RamBanksSmall	fdb	FirstRam,$1000
		fdb	$1000,$2000

; RAM banks if using 16K or 64K RAMS
RamBanksLarge	fdb	FirstRam,$4000
		fdb	$4000,$8000

BankTableSize	equ	(RamBanksLarge-RamBanksSmall)

;
; Quick RAM test
; 
; Entry:
;	A	= 0, start test from beginning <>0 restart test from last
;	X	= base of area to test
;	Y	= length of area to test
;
; Exit:
;	CC.C	= error
;	X	= error address
;
QRamTest	tst	TestContinue	; should we start from beginning ?
		beq	QRamTestStart	; yes, start from beginning
		
		tst	TestWrote	; what was the last value written?
		beq	QRamTestP1	; we where on pass with $00, continue it
		bra	QRamTestP0	; we where on pass with $FF, continue it
		
QRamTestStart	stx	TestBase	; save base of test
		sty	TestEnd		; save end of test
		
QRamTestP0	clra			; do a pass with $FF
		coma			
		bsr	QPass		; test it
		bne	QRamTestExit	; error, exit
		
QRamTestP1	clra			; do a pass with $00
		bsr	QPass		; test it

QRamTestExit	pshs	cc		; save codes
		puls	cc,pc		; restore and return
		
;
; QPass, do the actual testing of the RAM, called by QRamTest and
; LRamTest, returns with CC.Z set on sucesss, clear on failure.
;
; TestPage1, TestDPlus, TestDPlusBank should be setup before calling
; this routine will page in / out memory as needed.
;
; On failure the RAM vars TestRead, TestWrote and TestFailAddr are
; set, so that thgese can be displayed to the user.
;		
		
QPass		pshs	a		; save test value

		bsr	PageInRAM	; page RAM in

		tst	TestContinue	; are we continuing a test?
		beq	QPassStart	; no, start from beginning
		
		ldx	TestFailAddr	; get address to continue from
		ldb	TestSaved	; get saved value
		lda	TestWrote	; get test value
		bra	QPassContinue	; go continue test
		
QPassStart	ldx	TestBase	; get base of test
	
; Test the RAM		
QPassLoop	
		ldb	,x		; get current value in b
		tfr	d,y		; save ram value and test value in y
		sta	,x		; store test value in RAM
		eora	,x		; is it the same?
		bne	QPassErr	; nope....exit
		
QPassContinue	tfr	y,d		; restore saved values
		stb	,x+		; replace old contetnts
		cmpx	TestEnd		; reached last yet?
		bne	QPassLoop	; loop again if more
		
		clrb			; set flags to zero, flag we passed
		bra	QPassExit	; return to caller
		
QPassErr	sta	TestRead	; save written eor read value
		tfr	y,d		; restore saved values
		sta	TestWrote	; save written value
		eora	TestRead	; restore read value
;		lda	,x		; get read back value
		sta	TestRead	; save it
		stx	TestFailAddr	; save fail address
		stb	TestSaved	; save the original data
		
		andcc	#~FlagZero	; flag failure

QPassExit	bsr	PageOutRAM	; Page RAM out.
		puls	a,pc		; restore and return

; Page in the RAM under test
PageInRAM	pshs	a
		tst	TestPage1	; are we testing upper RAM?
		beq	PageInDPlus	; no skip
		clr	SAMSP1		; set SMA Page 1
		
PageInDPlus	tst	TestDPlus	; are we testing Dragon plus banks?
		beq	PageInExit	; no, skip

		lda	TestDPlusBank	; get bank under test
		sta	PlusBank	; set it
	
PageInExit	puls	a,pc

; Page out RAM once done		
PageOutRAM	pshs	cc		; save codes
		clr	SAMCP1		; back to page 0 for output
		clr	PlusBank	; Select normal Dragon RAM
		puls	cc,pc		; restore and return



;
; Long RAM test
; 
; Entry:
;	X	= base of area to test
;	Y	= length of area to test
;
; Exit:
;	CC.Z	= error
;	X	= error address
;
; On failure the RAM vars TestRead, TestWrote and TestFailAddr are
; set, so that thgese can be displayed to the user.

LRamTest	bsr	LTestSetLeds	; setup leds

		tst	TestContinue	; should we start from beginning ?
		beq	LRamTestStart	; yes, start from beginning

		bra	LRamTestLoop	; re-enter test loop
		
LRamTestStart	stx	TestBase	; save base of test
		sty	TestEnd		; save end of test
	
		clra			; do a pass with $00
LRamTestLoop	bsr	LProgress	; show progress
		
		bsr	QPass		; test it
		bne	LRamTestExit	; error, exit
		
		inca			; text next value
		bne	LRamTestLoop	; loop if not zero
		
LRamTestExit	pshs	cc		; save flags
		lda	SaveLEDS	; put LEDS back
		sta	LEDS
		puls	cc,pc		; restore and return

LTestSetLeds	lda	LEDS		; get current leds value
		sta	SaveLEDS	; save them
		lda	#$01		; init LEDS animation
		sta	LEDS
		clr	LEDDir		; increment.
		rts

; display progress of long test so we know it hasn't crashed!

LProgress	pshs	d		; save regs

ShowProgress	ldx	CursorPos	; get cursor position
		stx	SaveCursorPos	; save it
		lbsr	VDollar		; print $dollar
		
		ldd	#$0001		; column 12 line 2
		lbsr	LCDGotoXY	; go to co-ordinates
		
		leax	LTestValue,pcr	; print message
		lbsr	LCDWriteStr	; write it
		
		ldd	,s		; recover saved value
		lbsr	DevHexByte	; print it
		
		ldx	SaveCursorPos	; restore the cursor position
		stx	CursorPos
		
		lda	LEDS		; get current LEDS value
		tst	LEDDir		; check direction
		bne	LEDSDec		; decrement
		lsla			; shift them left
		cmpa	#$80		; reached far left?
		beq	LEDSRev		; reverse direction next time
		bra	LEDSUpdate	; update

LEDSDec		lsra			; shift right
		cmpa	#$01		; reached far right?
		bne	LEDSUpdate	; nope update
		
LEDSRev		com	LEDDir		; reverse direction next time
		
LEDSUpdate	sta	LEDS		; update LEDS		
		
LProgressExit	puls	d,pc		; restore and return

;
; Test for potential Address line breaks / shorts
;

	ifndef Test
AddrTestBase	EQU	$0000
AddrTestLEnd	EQU	$0400
	else
AddrTestBase	EQU	$4000
AddrTestLEnd	EQU	$4400
	endc	

AddressRAMTest	lbsr	LCDClrScr	; Clear LCD display, CR on VDG
		leax	LAddr07Test,pcr	; point at message
		lbsr	DevWriteStr	; display it
		
		ldx	#AddrTestBase	; start of RAM test
		stx	TestBase
		ldx	#AddrTestLEnd	; end of RAM test
		stx	TestEnd		; save it
		
		lbsr	SaveScreen	; save scren buffer in SRAM
		
		clra			; clear a
		
		ldx	TestBase
LWriteLoop	sta	,x+		; save a byte in RAM
		inca			; increment byte
		cmpx	TestEnd		; end of block to write?
		bne	LWriteLoop	; no loop again
		
		clra			; clear vars
		clrb
		ldx	TestBase	; get base of test area
LReadLoop	ldb	,x		; get a byte from area
		pshs	b		; save on stack (in our SRAM)
		cmpa	,s+		; is it same as written value?
		bne	AddrTestFail	; nope! Fail!
		
		leax	1,x		; increment pointer
		inca			; and value
		cmpx	TestEnd		; end of block to read?
		bne	LReadLoop	; no go again.
		
		lbsr	RAMPassed	; display passed message
		
		lbsr	LCDClrScr	; Clear LCD display, CR on VDG
		leax	LAddr9FTest,pcr	; point at message
		lbsr	DevWriteStr	; display it
		
		lbsr	SaveScreen	; save scren buffer in SRAM
		
		ldx	#AddrTestBase	; start of RAM test
		stx	TestBase
		
		leax	RamBanksSmall,pcr	; assume 4K
		tst	RAMFlag		; are we configured for 4K rams?
		beq	AddrSetBanks	; yes use them
		
		leax	BankTableSize,x	; select large table

AddrSetBanks	ldb	RAMFlag		; Check RAM size
		cmpb	#DRAM64		; Check to see if we have 4K or 16K RAMS
		blo	AddrCheckOne	; no check for one bank
		
AddrNextEntry	leax	4,x		; next table entry
		bra	AddrSetEnd	; set ennd address
		
AddrCheckOne	ldb	#DIPOneBank	; just do one bank?
		lbsr	DIPMask		; test it
		beq	AddrNextEntry	; no point to second bank

AddrSetEnd	ldx	2,x		; get end address
		stx	TestEnd		; save it in end address to test
		
		ldx	TestBase	; get start address
UWriteLoop	tfr	x,d		; transfer it to d
		sta	,x+		; write MSB to RAM, this is the page no
		cmpx	TestEnd		; reached end address
		bne	UWriteLoop	; nope keep going
	
		ldx	TestBase	; get start address
UReadLoop	tfr	x,d		; transfer it to d
		ldb	,x		; get value from RAM
		pshs	b		; save it on stack in SRAM
		cmpa	,s+		; is it the same
		bne	AddrTestFail	; nope : display failure
		
		leax	1,x		; move to next byte
		cmpx	TestEnd		; reached end?
		bne	UReadLoop
		
		lbsr	RestoreScreen	; restore screen from SRAM
		lbsr	RAMPassed	; display passed message
		rts
		
AddrTestFail	stx	TestFailAddr	; save fail values
		sta	TestWrote
		stb	TestRead
		andcc	#~FlagZero	; flag failure
		lbsr	RestoreScreen	; restore screen from SRAM
		lbsr	RAMFail		; display fail address
		rts
;
; Checksum ROMs
;
; ROM checksums, in the Dragon 32 and early CoCos these are 2 separate ROMS
; in the Dragon 64 and later CoCos these are one single ROM.
; I may at some point also Checksum the RAM mode ROM on a D64 (or Alpha).
		
ChecksumROMS	lbsr	LCDClrScr	; Clear LCD screen
		
		leax	LMessCSum80,pcr	; point to LCD message
		lbsr	DevWriteStr	; write it to LCD
	
		ldu	#$8000		; first rom $8000-$9FFF
		ldy	#$A000
		lbsr	ChecksumROM	; go get checksum
		
		inc	LEDS
				
		lbsr	VCRLCDClrScr	; Clear LCD screen
		leax	LMessCSumA0,pcr	; point to LCD message
		lbsr	DevWriteStr	; write it to LCD

		ldu	#$A000		; second rom $A000-$BFFF
		ldy	#$C000
		lbsr	ChecksumROM	; go do checksum

		inc	LEDS
		lbsr	Newline		; and newline
		
		rts

ChecksumROM	tfr	u,x		; get base address
		pshs	u		; save base address for later
		lbsr	ChecksumMem	; go calculate checksum
		
		pshs	d
		lbsr	DevHexWord	; output it
		
		lbsr	VSpace		; output a space
		lbsr	LCR		; CR to LCD
		puls	d
		puls	u		; recover base adddress
		lbsr	RomID		; identify ROM
		
		lbsr	WaitPause	; Wait for user to read results
		lbsr	WaitPause	; Wait for user to read results
		rts

;
; Checksum a block of memory.
;
; Entry:
;	X 	= start address
;	Y	= end address
;
; Exit:
;	D	= checksum
;

ChecksumMem	pshs	x,y		; save end address
		clra			; D=0
		clrb
ChecksumLoop	addd	,x++		; add a byte from emory block
		cmpx	2,s		; reached end yet?
		blo	ChecksumLoop

		puls	x,y,pc		; restore and return

;
; Test Interrupts
;
InterruptTest	lbsr	LCDClrScr	; clear LCD screen
		lda	#DevVDG+DevLCD	; set output device to both
		sta	OutputFlag
	
		ldd	NMICount	; get NMI counter
		leax	LSpuriousNMI,pcr ; point to message
		bsr	IntShow
		
		ldd	FIRQCount	; get NMI counter
		leax	LSpuriousFIRQ,pcr ; point to message
		bsr	IntShow
		
		lbsr	WaitPause	
	
		lbsr	VCRLCDClrScr	; Clear LCD screen, CR on VDG
	
		leax	LWaitNMI,pcr	; Wait for NMI message
		lda	#NMITrigger	; flag to CPLD to trigger int after delay
		bsr	WaitForInt
		
		lbsr	DCR		; Eol sequence
		
		leax	LWaitFIRQ,pcr	; Wait for NMI message
		lda	#FIRQTrigger	; flag to CPLD to trigger int after delay
		bsr	WaitForInt
		
		lbsr	WaitPause	
		rts
		
		
WaitForInt	lbsr	DevWriteStr	; write string
		
		sta	WaitInt		; int we are waiting for
		clr	GotInt		; clear Int received flag
		
		pshs	a		; save a
		lda	StatusReg	; get current status reg
		ora	,s+		; combine with flag
		sta	StatusReg	; tell CPLD to trigger it
		
		lbsr	Wait		; wait for it.......
		
		lda	GotInt		; check to see if we got an int.....
		anda	WaitInt			
		bne	WeGotInt	; yes display

		leax	LTimeout,pcr	; no int received, tell user
		bra	DisplayInt
		
WeGotInt	leax	LTriggered,pcr	; int received, tell user	

DisplayInt	lbsr	DevWriteStr	; display it
		rts

IntShow		pshs	d
		lbsr	DDollar		; write dollar sign
		puls	d
		lbsr	DevHexWord	; output it
		
		lbsr	DevWriteStr	; write string
		rts

;
; Cart line tests for CTS / P2
;
CartLineTest	lbsr	VCRLCDClrScr	; clear LCD screen
		
		leax	LCartTest,pcr	; Display message
		lbsr	DevWriteStr	

		lda	StatusReg	; Read current P2 & CTS status, should both be high.
		anda	#StatusCART	; Check current status
		cmpa	#StatusCART	; are they both high?
		beq	CartTest

		pshs	a		; save line status	
		leax	LCartError,pcr	; Point to error message
		lbsr	DevWriteStr	; write message
		
		puls	a
		lbsr	DevHexByte	; output line status
		bra	CartLineExit 	; return without test
		
CartTest	leax	LWaitP2,pcr	; point to test name
		ldy	#TriggerP2	; address to trigger it
		ldb	#StatusP2Latch	; Status mask
		bsr	WaitLine	; go test it
		
		leax	LWaitCTS,pcr	; point to test name
		ldy	#TriggerCTS	; address to trigger it
		ldb	#StatusCTSLatch	; Status mask
		bsr	WaitLine	; go test it	
CartLineExit
		lbsr	VCR		; End on new line
		lbsr	WaitPause
		rts

WaitLine	lbsr	DevWriteStr	; Write the test message
		
		pshs	b		; save mask on stack
		clr	StatusReset	; clear the latch
		
		lda	,y		; access the test location
		nop			; just for luck.....
		lda	StatusReg	; get status register
		
		anda	,s+		; mask bit out
		beq	WaitLineFail	; bit not latched, we fail
		
		leax	LPass,pcr	; point at pass message
		bra	WaitLineMess	; go write it
		
WaitLineFail	leax	LFail,pcr	; point at fail message

WaitLineMess	lbsr	DevWriteStr	; go write pass / fail	
		lbsr	DSpace		; display a space	
		clr	StatusReset	; clear the latch
		rts
;
; ROM ID, from checksum.
;
; Entry : 	D = Checksum
;		U = Expected base address
;

; Length of checksum, pageno and string.
RomStrLen	EQU	6
ROMRecordLen	EQU	(2+1+RomStrLen)
	
RomID		pshs	d,x
		tfr	u,d		; get rom page into A
		pshs	a		; save on stack for below
		
		leax	(ChecksumTable-ROMRecordLen),pcr	; point to table
RomIDLoop	leax	ROMRecordLen,x	; Move to next record

		ldd	,x		; get a word from table
		beq	RomIDFound
		
		cmpd	1,s		; compare to checksum passed in
		bne	RomIDLoop	; not same, loop again

RomIDFound	pshs	x		; save table pointer
		leax	3,x		; Point at string
		ldb	#RomStrLen	; length of string	
		lbsr	DevWriteStrN	; write characters from table
		lbsr	VCR		; CR to the VDG
		puls	x		; restore table pointer

		lda	2,x		; Get expected page
		cmpa	#PageInvalid	; not a real expected page?
		beq	RomIDEnd	; yep skip
		
		cmpa	,s		; is expected page same as found page?
		bne	RomIDPage	; yep flag it!
	
		leax	LCorrect,pcr	; show correct location
		bra	RomIDShow	; show it....

RomIDPage	leax	LWrong,pcr	; Show wrong location....	
RomIDShow	lbsr	DevWriteStr	; write it

RomIDEnd	leas	1,s		; drop saved ROM page
		puls	d,x,pc
	
;
; ROM checksum table, consists of records formatted as so :
;
; Offset	Length	Use
; 0		2	ROM checksum value
; 2		1	ROM start Page e.g. $80, $A0, $C0, $E0
; 3		6	ASCII ROM name.
; 	

PageInvalid	EQU	$FF		; Nota a valid checksum, mark it.

ChecksumTable	
		FDB	$B44F		; Dragon 32
		FCB	$80	
		FCC	"D32 LO"
		
		FDB	$DACC	
		FCB	$A0
		FCC	"D32 HI"	
		
		FDB	$D753		; Dragon 64, ROM mode
		FCB	$80	
		FCC	"D64 LO"
		FDB	$1968	
		FCB	$A0	
		FCC	"D64 HI"
		
		FDB	$E334
		FCB	$A0
		FCC	"T64 HI"	; Tano D64, yes it's different from D64.
		
		FDB	$677C		; Color basic 1.0
		FCB	$A0	
		FCC	"CB 1.0"	
		
		FDB	$8DC2		; Color basic 1.1
		FCB	$A0	
		FCC	"CB 1.1"	
		
		FDB	$1313		; Color basic 1.2
		FCB	$A0	
		FCC	"CB 1.2"	
		
		FDB	$9E9F		; Color basic 1.2, CoCo3
		FCB	$A0	
		FCC	"CB 1.2"
		
		FDB	$AD56		; Color basic 1.3
		FCB	$A0	
		FCC	"CB 1.3"

		FDB	$9E87		; Extended color basic 1.0 (C) 1980, from CoCo1
		FCB	$80	
		FCC	"ECB1.0"
		
		FDB	$AF87		; Extended color basic 1.0 (C) 1981, from MESS
		FCB	$80	
		FCC	"ECB1.0"
		
		FDB	$40AC		; Extended color basic 1.1
		FCB	$80	
		FCC	"ECB1.1"
		
		FDB	$7F63		; Extended color basic 2.0, CoCo3
		FCB	$80	
		FCC	"ECB2.0"
		
		FDB	$541A		; CoCo3 $C000-$DFFF 'patch' rom
		FCB	$C0	
		FCC	"CC3-PR"
		
		FDB	$C0E6		; CoCo3 Super Extended Colour basic
		FCB	$E0	
		FCC	"SECB 1"
		
		FDB	$F88D		; LZ Colour 64, ECB 1.0, CB 1.1 (clone/pirate).
		FCB	$80	
		FCC	"ecb1.0"
		
		FDB	$E321	
		FCB	$A0	
		FCC	"cb 1.1"
		
		FDB	$986B		; MX-1600, ECB 1.1, CB ??? (clone/pirate).
		FCB	$80	
		FCC	"ecb1.1"
		
		FDB	$96BF	
		FCB	$A0	
		FCC	"cb ???"
		
		FDB	$7733		; CP400, ECB ???, CB ??? (clone/pirate).
		FCB	$80	
		FCC	"ecb???"
		
		FDB	$5732	
		FCB	$A0	
		FCC	"cb ???"
		
		FDB	$E619		; DraCo, colour basic 1.2 modified for Dragon hardware
		FCB	$A0	
		FCC	"cb1.2d"
		
		FDB	$7A31		; Dragon 64 RAM mode ROM, lo
		FCB	$80	
		FCC	"D64-LO"
		
		FDB	$ABE9		; Dragon 64 RAM mode ROM, hi
		FCB	$A0	
		FCC	"D64-HI"
		
		FDB	$FFFF
		FCB	PageInvalid
		FCC	"NO ROM"
		
		FDB	$0000
		FCB	PageInvalid
		FCC	"UNKOWN"
ChecksumTableEnd		
		
;
; Dump PIAs
;		
		
DumpPIAS	lbsr	VCRLCDClrScr	; Clear LCD

		leax	LPIATest,pcr	; point at PIA test message
		lbsr	DevWriteStr	; and write it
		
		lbsr	WaitPause	; wait with pause
		
		leau	DragonPIA,pcr	; point at Dragon PIA table
		ldb	#DIPDgnCoCo	; is it a dragon or CoCo?
		lbsr	DIPMask		; go claculate
		bne	DumpDragon	; it's a Dragon already pointin at it's table
		leau	CoCoPIA,pcr	; point at CoCo PIA table

DumpDragon	leax	LPIA0Mess,pcr	; display message for PIA0
		lbsr	LCDClrWriteStr	; Clear screen, Write it
		
		ldx	#PIA0DA		; point at PIA
		bsr	GetPIADisplay	; get and display

		leax	LPIA1Mess,pcr	; display message for PIA0
		lbsr	LCDWriteStr	; Write it

		ldx	#PIA1DA		; point at PIA
		bsr	GetPIADisplay2	; get and display

		lbsr	VCR		; EOL on screen
		lbsr	WaitPause	; wait with pause
		rts
		
GetPIADisplay	lbsr	Newline		; make sure we are at beginning of line
		
GetPIADisplay2	ldy	CursorPos	; save current cursor position
		sty	SaveCursorPos	
		
		pshs	x
		
		leax	MessPA,pcr	; point to message
		lbsr	WriteStr	; display it
				
		puls	x		; recover PIA pointer
		
		pshs	u
		ldu	#PIABuff	; point at PIA value buffer
		lbsr	GetPIA		; get it's values
		puls	u
		
		ldx	SaveCursorPos	; recover cursor pos
		stx	CursorPos
		
		ldy	#PIABuff	; point at PIA value buffer
		lda	#6		; 6 values
		pshs	a		; save counter on stack
		
		ldb	#2		; move cursor 2 places forward
		
NextPIAReg	lbsr	CursorMove	; move it

		lda	,y+		; get a value from buffer
		lbsr	DevHexByte	; output value
		
		lda	,s		; get counter

		cmpa	#$04		; done 3 values (not decremented till end of loop)?
		beq	PIASpace	; yes output space not dash
		cmpa	#$01		; end of values.....
		beq	PIASpace	; yes output space not dash
		
		lda	#'-'		; dash between values on LCD
		
		fcb	Skip2		; skip 2 bytes
PIASpace	lda	#' '		; output a space to LCD	
		lbsr	LCDWriteChar	; output to LCD
		
		ldb	#3		; 3 spaces forward (on next loop)
		
		dec	,s		; decrement counter
		bne	NextPIAReg	; keep going if more to do

; check read PIA registers (control and DDR) against expected values
		
CheckPIA	lda	#2		; 2 loops
		pshs	a
		clr	1,s		; clear byte on stack, check flag
		
		ldy	#PIABuff-3	; point at PIA value buffer
CheckPIALoop	leay	3,y		; point to next group of registers
		lda	1,y		; get CR
		anda	#CRMask		; mask out input bits
		cmpa	,u+		; check against expected value
		beq	ValOK		; it's OK
		inc	1,s		; flag bad
		
ValOK		lda	2,y		; get read ddr
		cmpa	,u+		; check ddr
		beq	ValOK2
		inc	1,s		; flag bad
	
ValOK2		dec	,s		; decrement counter
		bne	CheckPIALoop	; do B side

		leax	MessOK,pcr	; assume values OK
		lda	#'Y'		
		tst	1,s		; test ok flag
		beq	PIAAllOK	; yep the're OK
		leax	MessNO,pcr	; not ok message
		lda	#'N'
		
PIAAllOK	lbsr	LCDWriteChar	; write LCD
		lbsr	WriteStr	; write to VDG 	
		puls	d,pc		; restore and return

CRMask		EQU	$3F		; mask to read Control regsiter values, ignore input bits

; tabe to test PIA values
DragonPIA	FCB	$34,$00		; PIA 0, CRA,DDRA
		FCB	$35,$FF		; PIA 0, CRB,DDRB
		FCB	$34,$FE		; PIA 1, CRA,DDRA
		ifndef	Test
		FCB	$35,$F8		; PIA 1, CRB,DDRB
		else
		FCB	$35,$F8		; PIA 1, CRB,DDRB
		endc
		
CoCoPIA		FCB	$34,$00		; PIA 0, CRA,DDRA
		FCB	$35,$FF		; PIA 0, CRB,DDRB
		FCB	$34,$FE		; PIA 1, CRA,DDRA
		ifndef	Test
		FCB	$35,$F8		; PIA 1, CRB,DDRB
		else
		FCB	$35,$F8		; PIA 1, CRB,DDRB
		endc
	
;
; Test to see if CPU is a 6809 or 6309.
;	
; 
GetCPUType	
;		lbsr	LCDClrScr	; clear LCD screen
		leax	LCPUIs,pcr	; point to message
		lbsr	DevWriteStr	; write it
		
		ldb	#$ff		; setup b
		FCB	$10		; This will be CLRD on 6309, CLRA on 6809
		clra
		tstb			; is b zero?
		
		beq	Is6309		; yes, 6309
		
		leax	LCPU6809,pcr	; 6809 messsage
		bra	ShowCPU		

Is6309		leax	LCPU6309,pcr	; 6809 messsage
ShowCPU		lbsr	DevWriteStr
		lbsr	VCR
		lbra	WaitPause	; wait a while
