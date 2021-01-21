;
; Hardware related routines for Diag cart
;


HWBase		EQU	$FF40		; base hardware address
LEDS		EQU	$FF40		; LEDS, I/O register
LEDS2		EQU	$FF41		; second group of LEDS

LED2IRQ		EQU	%00000001	; LED to flash on IRQ
LED2Pause	EQU	%00000010	; LED to light when in pause

; Dipswitches arwe bottom 4 bits, pushbuttons are top 4.
DIPSw		EQU	HWBase+2	; dipswitches for machine type 
Buttons		EQU	HWBase+3	; Buttons

; DIP switch constants
DIPSMask	EQU	%00001111	; 4 DIP switches
DIPCMask	EQU	%11110000	; control dip switches.

;DIP masks
DIPLoopTest	EQU	%10000000	; Loop tests, when we reach the end of all tests, run again
DIPNoDelay	EQU	%01000000	; Don't delay between tests.
DIPSkipLong	EQU	%00100000	; Skip long tests
DIPOneBank	EQU	%00010000	; only test one bank of 4K or 16K RAMS

DIPDgnCoCo	EQU	%00001000	; Dragon (1) or CoCo (0)
DIPSetRAM	EQU	%00000100	; Directly set RAM type from DIP 1 and 2
DIPMachineMask	EQU	%00000011	; Mask for bits that set machine
DIPDRAMMask	EQU	%00000011	; Mask for extracting DRAM type

; Dragons, valid with DgnCoCo=1
DIPD64		EQU	%00000001	; If Dragon is D64 
DIPDAlpha	EQU	%00000010	; if Dragon is Alpha

; CoCos, valid with DgnCoCo=0
DIPCoCo12	EQU	%00000000	; CoCo1, CoCo2
DIPCoCo3	EQU	%00000001	; CoCo3

DIPMaskD32	EQU	DIPDgnCoCo
DIPMaskD64	EQU	(DIPDgnCoCo+DIPD64)
DIPMaskAlpha	EQU	(DIPDgnCoCo+DIPDAlpha)

;DIPTest		EQU	DIPMaskD32+DIPSkipLong+DIPLoopTest+DIPNoDelay	; +SkipLong	; when testing with Mame/Mess, dip switches will read this
;DIPTest		EQU	DIPMaskD32	; +SkipLong	; when testing with Mame/Mess, dip switches will read this
DIPTest		EQU	DIPMaskD64+DIPSkipLong
;DIPTest			EQU	DIPCoCo3

; psuhbuttons
ButtonMask	EQU	%00001111	; 4 pushbuttons
ButtonNext	EQU	%00000001	; To move to next test
ButtonPause	EQU	%00000010	; To pause tests
ButtonS3	EQU	%00000100	; S3, currently unused
ButtonS4	EQU	%00001000	; S4, currently unused

ButtonSkip	EQU	ButtonS3	; skip button

ButtonNoWait	EQU	ButtonNext+ButtonPause	; press these at startup to skip waits

StatusReg	EQU	HWBase+4	; Status register

; status register constants
StatusReady	EQU	%10000000	; Set this in status register once init done.
StatusNMICount	EQU	%01000000	; NMI trigger is counting
StatusFIRQCount	EQU	%00100000	; FIRQ trigger is counting
StatusDisable	EQU	%00010000	; Disable mapping in of onboard RAM and ROM, 
StatusP2Latch	EQU	%00001000	; P2 access was latched
StatusCTSLatch	EQU	%00000100	; CTS access was latched
StatusP2	EQU	%00000010	; Live P2 level
StatusCTS	EQU	%00000001	; Live CTS level

; also used as flags in WaitInt
NMITrigger	EQU	%01000000	; Write to status register to trigger NMI
FIRQTrigger	EQU	%00100000	; Write to status register to trigger FIRQ

StatusCART	EQU	(StatusP2+StatusCTS) ; live CART line status

StatusReset	EQU	StatusReg+1	; To reset P2 / CTS latches

TriggerP2	EQU	$FF50		; Access here to trigger P2
TriggerCTS	EQU	$DEFF		; Access here to trigger CTS

LCDCmdStat	EQU	HWBase+8	; Character LCD Command/Status register
LCDData		EQU	HWBase+9	; Character LCD Data register 

;
; Output value of LEDS to physical LEDS
;
LEDNext		inc	LEDS		; Increment LED value
		rts
		
LEDFromA	sta	LEDS		; output them
		rts

; 
; Get value of DIPSw and mask
;
; Entry:	b=mask, exit b=DIPSw and mask
DIPMask		pshs	b		; save mask
		
		ifndef Test
		ldb	DIPSw		; get switches
		else
		ldb	TestDIP		; located at $c002, defined in DIPTest at top
					; of this file.
		endc
		
		andb	,s+		; mask them
		rts
;
; Check to see if machine is same as supplied in b
;
CheckMachine	pshs	b		; save a
		ldb	DIPSw		; get DIPS
		andb	#DIPSMask	; Mask out all but machine
		cmpb	,s		; same as supplied mask, set flags
		puls	b,pc		; recover machine, flags unaffected
		

;
; Initialize PIAs
;

SetupPIAs
	ldb	#DIPDgnCoCo		; is it a dragon or CoCo?
	bsr	DIPMask			; go claculate
	lbne	DragonPIAs		; Do dragon init

CoCoPIAs
	ldb	#DIPCoCo3		; is this a CoCo3?
	bsr	DIPMask			; go claculate
	beq	CoCo12PIA		; no just carry on with CoCo 1,2 
	
	com	IsCoCo3			; flag it's a CoCo3 to other tests
	lbra	InitCoCo3		; yes init coco3
	
CoCo12PIA
	ldx     #PIA1DA           	; point x to pia1 
        clr     -$1F,x            	; clear pia0 control register a 
        clr     -$1D,x            	; clear pia0 control register b 
        clr     -$20,x            	; set pia0 side a to input 
        ldd     #$ff34           
        sta     -$1E,x            	; set pia0 side b to output 
        stb     -$1F,x            	; enable pia0 peripheral registers, disable pia0 
        stb     -$1D,x             	; mpu interrupts, set ca2, ca1 to outputs 

	clr	1,x             	; clear control register a on pia1 
        clr     3,x             	; clear control register b on pia1 
        deca             		; a reg now has $fe 
        sta     ,x             		; bits 1-7 are outputs, bit 0 is input on pia1 side a 
        lda     #$f8 
        sta     2,x             	; bits 0-2 are inputs, bits 3-7 are outputs on b side 
        stb     1,x             	; enable peripheral registers, disable pia1 mpu 
        stb     3,x             	; interrupts and set ca2, cb2 as outputs 
        clr     2,x             	; set 6847 mode to alpha-numeric 
        ldb     #$02
        stb     ,x             		; make rs232 output marking 

        ldu     #SAMCV0			; zero sam bits for vdg mode & display offset
        ldb     #$10
@sam    sta     ,u++
        decb
        bne     @sam

        stb     SAMSF1			; Set display offset to $0400

; Detect RAM
	tst	IsCoCo3			; is this a CoCo3?
	bne	Ram64K			; flag as 64K rams.
	
	ldb	#$04			; mask for RAMZ input
	sta	-$1E,x			; a contains $F8, this sets output bit high
	bitb	2,x			; test RAM jumper input
	beq	Ram4K			; if low, we have 4K rams

	clr	-$1E,x			; set ram strobe low
	bitb	2,x			; test RAM jumper input
	beq	Ram64K			; followed strobe low so 64K
	
;	stb	SAMSM0			; program SAM for 1 or 2 banks of 16
	ldb	#DRAM16			; 16K rams
	stb	RAMFlag
	bra	LSamSetDRAM		; Go program SAM
	
Ram64K	
;	stb	SAMSM1			; program SAM for 1 of 64K
	ldb	#DRAM64			; 16K rams
	stb	RAMFlag
	bra	LSamSetDRAM		; Go program SAM
	
; settings are already correct for 4K RAMS.	
Ram4K	clr	RAMFlag			; flag 4K RAMS
LSamSetDRAM	
	lbra	SamSetDRAM		; Go program SAM
	
;
; Setup PIAs oon the Dragon.
;	
	
DragonPIAs
	LDD     #$0034			; Setup PIA0
        LDX     #PIA0DA
        STA     1,X			; zero ctrl regs, selects DDRs
        STA     3,X
        STA     ,X			; A=$00, $FF00 all inputs
        COMA				
        STA     2,X			; A=$FF, $FF02 all output
        STB     1,X			; $34, CB=output, IRQ disabled, Data reg selected
        STB     3,X

        LDX     #PIA1DA			; Setup PIA1
        CLR     1,X			; zero ctrl regs, selects DDRs
        CLR     3,X
        DECA				 
        STA     ,X			; A=$FE, B7..1=output, B0=input
        LDA     #$F8			
        STA     2,X			; A=$F8, B7..3=output, B2..0=input
        STB     1,X			; $34, CB=output, IRQ disabled, Data reg selected
        STB     3,X			
        CLR     ,X			; Zero outputs of PIA1DA
        CLR     2,X			; Zero outputs of $ff22

        LDA     2,X			; Read memory config bit from PIA, $ff22

	lda	PIA1DB			; Read memory config bit from PIA, $ff22
	
        ldx     #SAMCV0			; zero sam bits for vdg mode & display offset
        ldb     #$10
@sam    sta     ,x++
        decb
        bne     @sam

        stb     SAMSF1			; Set display offset to $0400

	ldb	#DIPD64			; are wa a dragon 64?
	lbsr	DIPMask			; read dips
	bne	RAM64			; yes set it
	
	bita	#$04			; Dragon 32, check if 2x16 or 1x64
	beq	RAM64			; 1x64

RAM16	
;	stb	SAMSM0			; 1 or 2 banks of 16K	
	ldb	#DRAM16			; Setup RAM flag

SetRAM	stb	RAMFlag		
	bra	SamSetDRAM		; Go program SAM	

RAM64	
;	STB     SAMSM1
	ldb	#DRAM64			; Setup RAM flag
	bra	SetRAM			; go set it

; Special initiaalization for CoCo3.
InitCoCo3
	lda	#Init1CoCo		; init in CoCo 1/2 mode
	sta	InitReg1
	clr	SAMCTY			; ROM / RAM mode

	if 0
; setup palette registers
	ldx	#PaletteBase		; point at palette registers
	lda	#$12			; base colour.....
	ldb	#$10			; 16 registers

Pal1	sta	,x+			; save colour
	decb				; decrement count
	bne	Pal1
	endc 

; init MMU registers
	leax	MMUInitData,pcr		; point at MMU initialization data
	ldy	#MMUBase		; point at base
	ldb	#MMUInitSize		; 16 MMU registers
	bsr	InitRegs		; copy it

	lda	#DefaultInit1		; default Init mode
	sta	InitReg1

	lbsr	CoCo12PIA		; Do CoCo 1/2 PIA / SAM init.
	
	clr	IRQEnableReg		; disable GIME IRQ interrrupts
	clr	FIRQEnableReg		; disable GIME FIRQ interrrupts

	leax	VidInitData,pcr		; point at init data
	ldy	#VideoReg		; point at video registers
	ldb	#VidInitSize		; number of bytes
	bsr	InitRegs		; copy it

	leax	PaletteInitData,pcr	; point at palette init data
	ldy	#PaletteBase		; point at palette registers
	ldb	#PaletteInitSize	; byte count
	bsr	InitRegs		; copy it
	
	rts

InitRegs
	lda	,x+			; get a byte
	sta	,y+			; put it in reg
	decb				; decrement count
	bne	InitRegs
	rts

MMUInitData
	FCB	Block70,Block71,Block72,Block73		; task register 0
	FCB	Block74,Block75,Block76,Block77
	
	FCB	Block60,Block61,Block62,Block63		; task register 1
	FCB	Block64,Block65,Block66,Block67
MMUInitSize	EQU	(*-MMUInitData)

; Video reg init data
VidInitData
;	FCB 	$06,$08,$00,$00		; $FF98 (VideoReg), $FF99 (VideoResReg)
;					; $FF9A (BorderReg), $FF9B (unused) 
;	FCB	$0F			; $FF9C (VScrollReg)
;	FCB	$E0,$80			; $FF9D (VertOddsetMSB), $FF9E (VertOffsetLSB)
;	FCB	$00			; $FF9F (HOffsetReg)
; Old values
	FCB 	$00,$00,$00,$00		; $FF98 (VideoReg), $FF99 (VideoResReg)
					; $FF9A (BorderReg), $FF9B (unused) 
	FCB	$0F			; $FF9C (VScrollReg)
	FCB	$E0,$00			; $FF9D (VertOddsetMSB), $FF9E (VertOffsetLSB)
	FCB	$00			; $FF9F (HOffsetReg)
VidInitSize	EQU	(*-VidInitData)	

; Old values
;	FCB 	$00,$00,$00,$00		; $FF98 (VideoReg), $FF99 (VideoResReg)
;					; $FF9A (BorderReg), $FF9B (unused) 
;	FCB	$0F			; $FF9C (VScrollReg)
;	FCB	$E0,$00			; $FF9D (VertOddsetMSB), $FF9E (VertOffsetLSB)
;	FCB	$00			; $FF9F (HOffsetReg)

PaletteInitData
	FCB 	18,36,11,7
	FCB	63,31,9,38
	FCB	0,18,0,63
	FCB 	0,18,0,38
PaletteInitSize	EQU	(*-PaletteInitData)	
;
; SamSetDRAM, program the SAM for the dram type.
; Checks to see if the direct RAM set switch is set, if so uses it's
; value (and updates the RAMFlag as well). Otherwise it uses the 
; RAMFlag value detected from the hardware. 
;
	
SamSetDRAM
	ldb	#DIPSetRAM		; check the jumper
	lbsr	DIPMask			; read dips
	beq	SamSetFromHW		; not set use detected value

	ldb	#DIPDRAMMask		; extract DRAM type bits
	lbsr	DIPMask			; read dips	
	stb	RAMFlag			; set RAMFlag

SamSetFromHW
	lda	RAMFlag			; read RAM type
	ldx	#SAMCM0			; point at memory type flags
	ldb	#2			; 2 bits

SamBitTest	
	lsra				; shift bottom bit into carry
	bcc	SamBitClear		; carry clear no need to set anything 
	sta	1,x			; set the bit

SamBitClear
	leax	2,x			; point at next bit
	decb				; decrement count
	bne	SamBitTest		; loop if more to do
	
	rts	
; 
; Clear a block of RAM
;
; Entry:
;	a	= value to clear to (if entered at RamClear)
;	x	= base of area to clear
;	y	= end of area to clear
;
	
RamZero		clra	
RamClear	pshs	y		; save terminating value on stack
RamClearLoop	sta	,x+		; clear a byte
		cmpx	,s		; reached end yet?
		bne	RamClearLoop	; nope continue
		puls	y,pc		; restore and return
	
;
; Set SAM's screen address.
;
; Entry:
;	X	= Screen address

SetSAMScr	pshs	x,d		; save regs
		tfr	x,d		; get address into d
		
		stx	ScreenBase	; save screen base
		leax	TextScreenLen,x	; Work out address of end of screen
		stx	ScreenEnd	; save screen end
		
		ldb	#7		; 7 sam address bits
		LDX     #SAMCF0		; point at SAM offset bits	
		rora			; onl7 7 bits to set

SetSamBits	rora			; get bit into carry
		bcs	SetSamBit		
		sta	,x		; clear sam bit
		bra	NextSamBit	; do next
		
SetSamBit	sta	1,x
NextSamBit	leax	2,x		; point to next bitset
		decb			; decrement count
		bne	SetSamBits	; more, keep going
		
		puls	x,d,pc		; restore and return

;
; GetPIA, get a PIA's registers
;
; Entry:
;	X	= PIA base address.
;	U	= 6 byte buffer for PIA regs
;
; Exit:
;	6 bytes in area pointed to by U : DA, CRA, DDRA, DB, CRB, DDRB
;

GetPIA		pshs	u		; save data pointer	
		
		ldd	,x		; get data + control register
		std	,u++		; stack them
		
		andb	#~CRDDRDATA	; select DDR register
		stb	1,x		
		lda	,x		; get DDR value
		sta	,u+		; save DDR value
		orb	#CRDDRDATA	; select data register
		stb	1,x
		
		leax	2,x		; move to side B
		
		ldd	,x		; get data + control register
		std	,u++		; stack them
			
		andb	#~CRDDRDATA	; select DDR register
		stb	1,x		
		lda	,x		; get DDR value
		sta	,u+		; save DDR value
		orb	#CRDDRDATA	; select data register
		stb	1,x
		
		puls	u,pc		; restore and return
		
;
; Check pause, check to see if pause button is pressed, 
; 	if so wait for it's release and invert pause flag.
; 

CheckPause	pshs	a		; save a
		lda	#ButtonPause	; pause button
		anda	Buttons		; is button pressed?
		beq	NoPause		; nope, just exit

WaitPauseUp	lda	#ButtonPause	; pause button
		anda	Buttons		; is button pressed?
		bne	WaitPauseUp	; wait for release
		
		com	Paused		; invert paused flag
		lda	#LED2Pause	; turn on LED
		eora	LEDS2
		sta	LEDS2
		
NoPause		puls	a,pc		; restore and return	
			
;
; WaitNext. wait for next button to be pressed and released.
;
WaitNext	pshs	a		; save a
		lda	#ButtonNext	; button to wait for
		bsr	ButtonWait	; go wait for press and release
		puls	a,pc		; restore and return
		
;
; ButtonWait, wait for the button in a to be pressed and released.
;		

ButtonWait	pshs	a		; save on stack
WaitDown	lda	,s		; Get button value from stack
		anda	Buttons		; is button pressed?
		cmpa	,s		; button pressed?
		bne	WaitDown	; no, wait till it's down
		
WaitUp		lda	,s		; Get button value from stack
		anda	Buttons		; is button pressed?
		bne	WaitUp		; yes, wait till it's rleased
				
		puls	a,pc		; restore and return

;
; Button pressed, is a button pressed.
;
ButtonPressed	pshs	a		; save button mask
		anda	Buttons		; mask in any being pressed
		cmpa	,s+		; was it the same as mask?
		rts
		
QueryButton	pshs	a
QueryButtonL1	lda	Buttons		; read buttons
		anda	#ButtonMask	; mask out invalid bits
		beq	QueryButtonL1	; loop until button pressed

		sta	,s		; save button for caller
QueryButtonL2	lda	Buttons		; read buttons
		anda	#ButtonMask	; mask out invalid bits
		bne	QueryButtonL2	; loop until buttons released
		puls	a,pc		; return values
