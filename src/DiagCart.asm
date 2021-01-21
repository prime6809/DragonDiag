		use 	ascii.asm
		use 	basicdefs.asm
		use	basictokens.asm
		use	coco3.asm
		use	cpudefs.asm
		use	dgndefs.asm
		use	romdefs.asm
		use	samdefs.asm
		use	wddefs.asm

IRQBlinkRate	EQU	50		; once / second at 50 hz

		ifndef Test
RAMPageNo	EQU	$E0		; Page no of RAM	
RAMBase		EQU	(RAMPageNo*256)	; base of RAM area.
RAMTop		EQU	RAMBase+$1EFF	; top of RAM
		else
RAMPageNo	EQU	$00		; Page no of RAM	
RAMBase		EQU	(RAMPageNo*256)	; base of RAM area.
RAMTop		EQU	RAMBase+$03ff	; top of RAM
		endc
		
DRAM4		EQU	0		; 1 or 2 banks of 4K rams (early CoCo only)
DRAM16		EQU	1		; 1 or 2 banks of 16K rams.
DRAM64		EQU	2		; 1 bank of 64K (or half good 64K)
DRAMStatic	EQU	3		; Static ram.

Bank4K		EQU	$1000		; 4K bank
Bank16K		EQU	$4000		; 16K bank

PrintBuffLen	EQU	80		; print buffer length
		org 	RAMBase

RamBegin		
; these will be in RAM on the card
RAMFlag		RMB	1		; RAM flag, ram chip type 0=4k, 1=16k, 2=64k	
SaveLEDS	RMB	1		; Temp save of current LEDS
LEDDir		RMB	1		; LEDS animation direction
IsCoCo3		RMB	1		; is this machine a CoCo3?
SavedS		RMB	2		; Saved stack pointer for CoCo3 RAM call.

; RAM test related
TestVector	RMB	2		; address of the test routine to use.
TestBase	RMB	2		; QRamTest / RamTest base
TestEnd		RMB	2		; QRamTest / RamTest last address to test +1
TestFailAddr	RMB	2		; QRamTest / RamTest failed at address
TestWrote	RMB	1		; QRamTest / RamTest written byte
TestRead	RMB	1		; QRamTest / RamTest read byte
TestSaved	RMB	1		; saved value when test failed....
TestPage1	RMB	1		; Are we testing page 1?
TestDPlus	RMB	1		; Are we testing Dragon Plus RAM?
TestDPlusBank	RMB	1		; Bank to set if testing DPlus
TestContinue	RMB	1		; are we starting a test from scratch or continuing?
CoCo3MinBank	RMB	1		; Minimum bank number for CoCo3 to test
CoCo3Blocks	RMB	1		; Ram test testing CoCo3 RAM blocks
CoCo3SaveBlock2	RMB	1		; Saved block2
CoCo3SaveBlock4	RMB	1		; Saved block4
CoCo3BlockNo	RMB	1		; Block number under test

; VDG screen related
ScreenOK	RMB	1		; Is it ok to use 6847 screen?
ScreenBase	RMB	2		; Screen base address
ScreenEnd	RMB	2		; End of screen RAM, just to make things easier!
CursorPos	RMB	2		; cursor address
SaveCursorPos	RMB	2		; saved cursor pos	

; Buffer for PIA registers
PIABuff		RMB	6		; Buffer for PIA values

; LCD related
LCDFlag		RMB	1		; LCD Initialized flag
LCDLineNo	RMB	1		; Current LCD line number

; User interface related
PrintBuff	RMB	PrintBuffLen+1	; print buffer, used by Hex routines amongst others
PrintBuffPos	RMB	2		; Address in print buffer
OutputFlag	RMB	1		; devices to output to.....
OldOutputFlag	RMB	1		; saved version of above
Paused		RMB	1		; are we paused or not?
NoWait		RMB	1		; Should we skip delays (except for errors?)

; Interrupt related
IRQCount	RMB	1		; IRQ counter
NMICount	RMB	2		; NMI counter
FIRQCount	RMB	2		; FIRQ counter
WaitInt		RMB	1		; interrupt wait flags
GotInt		RMB	1		; Int we got, see XXXWait flags below


; Temp screen buffer, note **MUST** come at end of RAM vars or DP offsets after it will 
; not work!
ScreenBuffer	RMB	TextScreenLen	; buffer for one screenfull.

RamEnd

DevVDG		EQU	%00000001	; vdg
DevLCD		EQU	%00000010	; lcd	

	
		org	CartBase
Start		bra	NewReset	; So we can be entered with EXEC &HC000

		ifdef Test
TestDIP		fcb	DIPTest		; test machine, defined in hardware.asm		
		endc

; Vector indirects, these mean the vectors at end of rom never need to change.
; ATTENTION! do ***NOT** change the filler below or updating ROM may break interface!

		zmb	((CartBase+$10)-*)
Signature	fcc	"DIAG"		; So flasher can recognize us.
		
IndirectVSWI3	jmp	NewSWI3
IndirectVSWI2	jmp	NewSWI2
IndirectVFIRQ	jmp	NewFIRQ
IndirectVIRQ	jmp	NewIRQ
IndirectVSWI	jmp	NewSWI
IndirectVNMI	jmp	NewNMI
IndirectVReset	jmp	NewReset
		
NewReset	orcc	#IntsDisable	; Disable ints so they are disabled if entered with EXEC
		clr	StatusReg	; Clear status
		clr	LEDS		; turn all LEDS off
		clr	LEDS2
	
; first test that we have usable SRAM on the card as we will put our vars and
; stack here, so we can still operate if main RAM is shot.

		ldx	#RAMBase	; point to base of RAM
		
SRAMTestLoop	cmpx	#RAMTop-2	; reached top of RAM?
		beq	SRAMOK		; yes SRAM is OK, continue

		lda	#$FF		; Test value
		sta	,x		; save it
		cmpa	,x		; same
		bne	SRAMFail	; nope fail
	
		com	,x		; invert
		tst	,x+		; is it zero?
		bne	SRAMFail	; nope fail
		bra	SRAMTestLoop
		
SRAMFail	com	LEDS		; flag SRAM fail!
L@		bra	L@		; loop forever

; So if we reach this point SRAM seems to be OK, so setup stack
SRAMOK		lds	#RAMTop-2	; setup stack pointer
		ldx	#RamBegin	; clear Ram vars
		ldy	#RamEnd		
		lbsr	RamZero		; go clear it

		lda	#RAMPageNo	; setup DP
		tfr	a,DP
		
		SETDP	RAMPageNo	; tell assembler

		ldb	#DIPNoDelay	; check to see if no wait dip is set
		lbsr	DIPMask	
		beq	SetupIRQ	; no, delays as normal
		
		dec	NoWait		; will make NoWait $ff
		
; Init IRQ blink counter so we know IRQ is working later on. For MAME emulation we also
; need to init the normal low ram secondary vector.
		
SetupIRQ	lda	#IRQBlinkRate	; setup for IRQ
		sta	IRQCount
		
; Flag that we are ready, and send Signon message to LCD, we can't use normal screen
; at this point as we have not verified that the screen RAM is OK 	
		lda	#StatusReady	; flag that we are ready in status register
		ora	StatusReg
		sta	StatusReg	; store it back
		
		lbsr	LCDInit		; try initializing LCD
		leax	LCDSignon,x	; point to message
		lbsr	LCDWriteStr	; write it to LCD.
		
		lda	#1		; Initialize LED value	
		sta	LEDS		; output LED value

; Setup PIAs, different routine if configured as Dragon or CoCo.
; On a Dragon 32 or CoCo 1/2 the RAM chip size jumpers are read and the SAM
; is programmed as needed.
		lbsr	SetupPIAs	; setup PIAs and SAM
		inc	LEDS

		lbsr	WaitPause	; Wait a delay

; check for button S4 pressed, if down show build date
		lda	#ButtonS4	; check for button S4 being pressed?
		lbsr	ButtonPressed	; 
		bne	NoDate		; no skip showing compile date

		lbsr	LCDClrScr	; clear LCD screen
		leax	LBuildDate,pcr	; point at message
		lbsr	LCDWriteStr	; display it
		
		leax	BuildDate,pcr	; point at build date
		lbsr	LCDWriteStr	; display it
		
		lbsr	WaitPause	; Wait a delay
		
NoDate		leax	LScreenRAM,pcr	; Point at screen ram test message
		lbsr	LCDClrWriteStr	; write it to LCD

; Tell the SAM where we have put the screen RAM
		lbsr	InitScreenVars	; Init screen vars, even if screen not OK
		inc	LEDS

; Test the screen RAM, if the screen RAM is OK, we can clear it and use the VDG
; as well as LCD for output.		
		ldx	#TextScreenBase	; point at text screen
		leay	TextScreenLen,x	; last address
		lbsr	QRamTest	; quick ram test	
		beq	ScreenRamOK	; screen RAM ok, use it for full tests
	
	
NoScreen	lbsr	RAMFail		; display ram fail message on LCD

		lda	LEDS		; mark fail
		ora	#$80
		sta	LEDS

		bra	QuickTest	; move on with LCD only	
		
ScreenRamOK	inc	ScreenOK	; it's OK to use VDG screen	
		lda	#DevVDG		; select VDG as output device
		ora	OutputFlag
		sta	OutputFlag

		lbsr	LCDPassed	; display passed message and wait a short while
		inc	LEDS

; Do quick RAM tests, just testing with $FF and $00		
QuickTest	lbsr	ShowMachine	; Show machine we are set to
	
		lbsr	GetCPUType	; Get show CPU type
		
		lbsr	DoQuickTest	; Do quick RAM test

; Address test, to try and detect address line errors.
		lbsr	AddressRAMTest	; Do RAM address line test 
		
; Checksum ROMS at $8000 and $A000, lookup checksums in table of known ROMS
; and identify them if found. 		
		lbsr	ChecksumROMS	; do ROM checksums
	
		lbsr	LCDClrScr	; Clear LCD screen
		leax	LIntsEnable,pcr	; point to message
		lbsr	DevWriteStr	; write it to LCD
		lbsr	WaitPause	; Wait for user to read results
		
		ifdef	Test
		orcc	#IntsDisable	; disable interrupts
		
		lda	#$7E		; opcode for JMP
		
		ldx	#NewIRQ		; setup low ram IRQ vector
		stx	SecVecIRQ+1
		sta	SecVecIRQ

		ldx	#NewFIRQ	; setup low ram FIRQ vector
		stx	SecVecFIRQ+1
		sta	SecVecFIRQ

		endc

		lda     PIA0CRB		; get pia0 control register B
		ora     #CRIRQ		; enable CB1 IRQ generation on /HS
		sta     PIA0CRB		; save it back to PIA0		
		
		ifndef	Test
		lda	PIA1CRB		; get PIA1, control register B
		ora     #CRIRQ		; enable CB1 FIRQ generation CART
		sta     PIA1CRB		; save it back to PIA1		
		endc
		
		andcc	#IntsEnable	; enable IRQ, FIRQ

; Dump contents of PIA registers, and test CRx and DDRx values have remained set		
		lbsr	DumpPIAS	; Dump PIA registers

; Test triggering of NMI and FIRQ, IRQ will be flashing LED if working.		
		inc	LEDS
		lbsr	InterruptTest	; Do interrupt test

; Test cartridge SCS / P2 and CTS / CART
		inc	LEDS
		lbsr	CartLineTest	; Test nCTS and nP2 cart lines	

; If enabled by DIP switch, do long tests
		leax	LMessBeginLong,pcr	; Begin long test message
		lbsr	DoLongTest	; do long RAM test

; If enabled by DIP switch do Dragon 64 tests
		lbsr	Dragon64Tests	; Go do Dragon64 only tests
		
; If we detected 64K DRAMS, test the upper 32K.		
		lbsr	RAM64Tests	; Go do upper RAM test if 64K rams	
; Probe for and test Dragon Plus addon.
		lbsr	PlusTests	; Test Dragon Plus

; If enabled by DIP switch do CoCo3 specific tests
		lbsr	CoCo3Tests	; test coco3

; Tests complete prompt user to run again.
		lbsr	VCRLCDClrScr	; clear LCD screen, CR on VDG
		leax	LComplete,pcr	; tests complete message
		lbsr	DevWriteStr	; go write it
		
		ldb	#DIPLoopTest	; should we test continually?
		lbsr	DIPMask		
		bne	LoopTest
			
		lbsr	WaitNext	; wait for next to be pressed

		lbsr	ToggleMode	; toggle mode!
		
LoopTest	lbra	NewReset	; go test again!
		

; Show what type of machine and configured RAM chip size.
ShowMachine	ldb	#DIPDgnCoCo	; test Dragon (1) or CoCo (0)
		lbsr	DIPMask		; test it
		bne	IsDragon	
		
		leay	LModelTableC,pcr ; point to CoCo name table
		bra	DoShow
		
IsDragon	leay	LModelTableD,pcr ; point to Dragon name table
		
DoShow		pshs	y		; save message pointer
;		ldd	#$0500		; X,Y = 5,0
;		lbsr	GotoXY
		
		leax	LMachineConf,pcr ; point at message
		lbsr	LCDClrWriteStr	; write it to LCD
				
		puls	y		; recover machine type name
		ldx	,y		; get address of machine type (Dragon or CoCo)
		lbsr	DevWriteStr	; write it to LCD and VDG

		ldb	#DIPSetRAM	; are we setting RAM directly?
		lbsr	DIPMask		; test it
		bne	ShowChip	; yes don't interpret machine type

		ifdef	Test
		lda	TestDIP
		else
		lda	DIPSw
		endc
		anda	#DIPMachineMask	; mask out machine
		
		leay	2,y		; point at machine names (32, 64, Alpha etc)
		lsla			; multiply a by 2 to get word offset
		ldx	a,y		; get address of machine type
		lbsr	DevWriteStr	; write it to LCD and VDG

; Write detected RAM *CHIP* type, 4K, 16K, 64K, this is detected at power on time
; from the chip select links on the Dragon 32 or CoCo motherboard.
; Since the Dragon 64 only ever has 64K chips, these are assumed rather than 
; detected, as there is no jumper to detect from.

ShowChip	leax	LRAMTable,pcr	; point at table
		lda	RAMFlag		; get chip type
		lsla			; multiply a by 2 to get word offset
		ldx	a,x		; get offset of message
		lbsr	DevWriteStr	; write it
		
		lbsr	VSpace
;		lbsr	WaitPause	; wait a while
		rts
	
		
;****[ Included modules: Tests ]******************************************			
		use	coco3tests.asm	; CoCo 3 specific tests, extra RAM, GIME etc.
		use	d64tests.asm	; Dragon 64 specific tests, ACIA etc
		use	dplustests.asm	; Dragon Plus detection and tests
		use	tests.asm	; test routines, RAM, Cartridge Interrrupts etc	
		use	togglemode.asm	; Test routines to toggle chip selects.
;****[ Included modules: drivers ]****************************************
		use	console.asm	; VDG text output routines
		use 	hardware.asm	; hardware initialization and defines
		use	lcd.asm		; LCD output routines
		use	outdev.asm	; Combined VDG /LCD output
		use	utils.asm	; various utility functions
;****[ Text modules ]*****************************************************			
		use	lcdtext.asm	; Text messages for LCD	
		use	vdgtext.asm	; Text messages for VDG (where different)
;****[ Build date ]*******************************************************			
BuildDate
		use	datetime.asm	
		fcb	0
;*************************************************************************			
		
NewSWI3		RTI
NewSWI2		RTI

; New FIRQ routine
NewFIRQ		tst	StatusReg	; Test status reg are we ready?
		bpl	SpuriousFIRQ	; no, it's spurious
		
DoFIRQ		pshs	a		; FIRQ only saves PC and CC
		lda	PIA1DB		; clear int
		
		lda	>WaitInt	; Get wait for int flag
		anda	#FIRQTrigger	; waiting for FIRQ?
		beq	SpuriousFIRQP	; no do spurious count
		
		sta	>GotInt		; otherwise flag we got the int.....
		puls	a		; restore a
		rti			; and exit
	
SpuriousFIRQP	puls	a	
SpuriousFIRQ	inc	FIRQCount+1	; increment spurious FIRQ counter
		bcc	FIRQExit	; no carry, exit
		inc	FIRQCount	; propagate carry

FIRQExit	RTI

; New IRQ routine
NewIRQ		lda	PIA0CRB		; check for frame sync int
		bpl	NewIRQEnd	; not frame sync, exit
		
		lda	PIA0DB		; read the PIA clear the int
		
		dec	>IRQCount	; decrement counter
		bne	NewIRQEnd	; not zero
		lda	#IRQBlinkRate	; re-initialize
		sta	>IRQCount

; Blink LED first character on screen, perhaps move to an LED for final hardware.	
		if 0
		ldx	>ScreenBase	; point at screen
		lda	#$80		; toggle tob bit of first char of screen
		eora	,x
		sta	,x		; and put it back
		endc
		
		lda	#LED2IRQ	; LED to blink
		eora	LEDS2		; combine
		sta	LEDS2		; save it back
		
NewIRQEnd	RTI
		
		
NewSWI		RTI

; new NMI 
NewNMI		tst	StatusReg	; Test status reg are we ready?
		bpl	SpuriousNMI	; no mark spurious
		
		lda	>WaitInt	; Get wait for int flag
		anda	#NMITrigger	; waiting for NMI?
		beq	SpuriousNMI	; no do spurious count
		
		sta	>GotInt		; otherwise flag we got the int.....
		RTI			; return
		

SpuriousNMI	inc	NMICount+1	; increment spurious NMI counter
		bcc	NMIExit		; no carry, exit
		inc	NMICount	; propagate carry
		
NMIExit		RTI

		
filler		zmb	(HWVecBase-*)	
; interrupt vectors		
		org 	HWVecBase
VecSWI3		FDB	IndirectVSWI3
VecSWI2		FDB	IndirectVSWI2
VecFIRQ		FDB	IndirectVFIRQ
VecIRQ		FDB	IndirectVIRQ
VecSWI		FDB	IndirectVSWI
VecNMI		FDB	IndirectVNMI
VecReset	FDB	IndirectVReset		
