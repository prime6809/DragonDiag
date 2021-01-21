; 
; Dragon Plus tests.
;

Plus6845Ctrl	equ	$FFE0		; 6845 control register
Plus6845Data	equ	$FFE1		; 6845 data register
PlusBank	equ	$FFE2		; memory bank register

PlusBankA	equ	%00000010	; bank A of extra ram
PlusBankB	equ	%00000110	; bank B of extra ram
PlusBankVideo	equ	%00000001	; 2K Video RAM

PlusVideoBase	EQU	$0000		; base of video RAM
PlusVideoEnd	EQU	$07FF		; End of plus video ram

PlusTests	tst	IsCoCo3		; is the machine a CoCo3?
		bne	PlusTestsEnd	; yes, DragonPlus not valid for CoCo3.
		
		leax	LProbeDPlus,pcr	; probe message
		lbsr	VCRLCDClrMess	; Clear LCD display, CR on VDG, write string
		
		bsr	ProbePlus	; probe for it
		beq	FoundTest
		
		leax	LProbeNotFound,pcr	; Not Found message
		lbsr	DevWriteStrWait	; write message and wait
		
		rts
		
FoundTest	leax	LProbeFound,pcr	; Found message
		lbsr	DevWriteStrWait	; write message and wait
		
		lbsr	InitCRTC	; Initialize CRTC
		lbsr	DisplayTest	; Display some test data
		
		leax	LDPlusVRTest,pcr ; point at message
		lbsr	VCRLCDClrMess	; Clear LCD display, CR on VDG, write string

		lbsr	Wait
		
		leay	PlusTestTable,pcr	; point at test table
		
PlusTestBanks	lda	,y		; get bank to test
		beq	PlusTestsEnd	; end of table exit
		
		leax	1,y		; point at start and end addresses
		pshs	y		; save y as it gets borked by ram tests
		bsr	TestPlusBank	; test the bank
		puls	y		; restore y
		
		leay	5,y		; point to next table entry
		bra	PlusTestBanks	; go test 	
		
PlusTestsEnd		
		rts

PlusTestTable	fcb	PlusBankVideo	; bank to test
		fdb	PlusVideoBase	; start address
		fdb	PlusVideoEnd	; end address
		
		fcb	PlusBankA	; bank to test
		fdb	$0000		; start address
		fdb	$7FFF		; end address
		
		fcb	PlusBankB	; bank to test
		fdb	$0000		; start address
		fdb	$7FFF		; end address

		fcb	$00		; terminator
;
; Probe for Dragon Plus.
;
		
ProbePlus	lda	#13		; Test R13, as this is readable
		sta	Plus6845Ctrl	; select horizontal total reg
		
		ldb	Plus6845Data	; save old value if any
		
		lda	#$55		; test value
		sta	Plus6845Data	; save value
		cmpa	Plus6845Data	; is it the same?
		bne	ProbePlusBad	; not found
		
		coma			; flip the bits
		
		sta	Plus6845Data	; save value
		cmpa	Plus6845Data	; is it the same?
		
ProbePlusBad	pshs	cc
		stb	Plus6845Data	; restore old value
		puls	cc,pc
		

;
; InitCRTC code borrowed from ED128.BIN
;
		

InitCRTC
		PSHS    X,B,A,CC	; save regs
		ORCC    #IntsDisable	; disable ints
		
		LDA     #PlusBankVideo	; select 6845 video RAM in $0000-$0800					
		STA     PlusBank				
		
		ifndef Test
		LDA     #$20		; space char
		LDX     #PlusVideoBase	; Fill video ram
ClearLoop
		STA     ,X+		; store it
		CMPX    #PlusVideoEnd+1	; done all?
		BNE     ClearLoop	; nope loop again
		endc 
		
		CLRA			; select default memory map
		STA     PlusBank
        
		CLRB			; Zero register no
		leax	CRTCRegValues,pcr	; point to register data
InitLoop
		STB     Plus6845Ctrl	; Set register to write
		LDA     ,X+		; get value
		STA     Plus6845Data	; Write it
		INCB			; do next register
		CMPB    #$10		; done all?
		BNE     InitLoop	; nope do next

		PULS    X,B,A,CC	; restore and return	
		RTS

;
; Test Plus RAM bank
;
; Entry :
;	A	= bank to test
;	X	= pointer to start and end address words
; Exit
;	CC.Z	= set on error
;	X	= error address
;
TestPlusBank	orcc	#IntsDisable	; disable interrupts
		
		sta	TestDPlusBank	; set bank we're testing
		clra	
		coma
		sta	TestDPlus	; flag testing DPlus RAM
		
		lbsr	GetTestLength	; setup test vector
		lbsr	DoRamTest	; long RAM test
		andcc	#IntsEnable	; enable interrupts
		
		pshs	cc		; save result
		clr	PlusBank	; back to normal RAM
		clr	TestDPlus	; clear  plus bank test
		
		puls	cc,pc		; restore and return
		
CRTCRegValues
		FCB    	$71		;  0 Horizontal Total = 113 
		FCB	$50		;  1 Horizontal Displayed = 80
		FCB	$5D		;  2 Horizontal Sync          
		FCB	$37		;  3 HSync Width+VSync        
		FCB	$19		;  4 Vertical Total           
		FCB	$1E		;  5 Vertical Adjust          
		FCB	$18		;  6 Vertical Displayed       
		FCB	$19		;  7 VSync Position           
		FCB    	$A2		;  8 Interlace+Cursor         
		FCB	$0A		;  9 Scan Lines/Character = 11
		FCB    	$60		; 10 Cursor start line        
		FCB	$0A		; 11 Cursor end scan line     
		FCB	$00		; 12 Screen Start Address High
		FCB	$00		; 13 Screen Start Address Low =
		FCB	$00		; 14 Cursor Address High
		FCB	$00		; 15 Cursor Address Low
		
DisplayTest
		pshs	cc	
		orcc	#IntsDisable	; disable ints
	
		lda	#PlusBankVideo	; select video ram
		sta	PlusBank
		
		ifndef Test
		ldx	#PlusMess	; point to message
		ldy	#0		; point to screen
		
CopyLoop	lda	,x+		; get a byte
		tsta			; end of message?
		beq	EndMess		; yep : exit
		sta	,y+		; put it on screen
		bra	CopyLoop	; do next

EndMess		ldy	#10*80		; print character set	
		
CharLoop	sta	,y+		; save character
		inca			; next character
		bne	CharLoop	 
		
		endc
		clr	PlusBank	; Reset to normal ram
		puls	cc,pc
	
PlusMess	FCN	'Dragon Plus video test.'		
		