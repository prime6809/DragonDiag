;
; Togglemode....toggle various chip selects.
;

ToggleMode
	pshs	cc			; save flags
	orcc	#IntsDisable
	lbsr	VCRLCDClrScr		; clear LCD screen, CR on VDG
	leax	ToggleLine,pcr		; Point to message	
	lbsr	LCDWriteStr		; write string on LCD
	
	leau	ToggleList,pcr		; Point to toggle list
	lbsr	VCR			; new line

	leax	ToggleLine,pcr		; Point to message	
	lbsr	WriteStr		; Write it
	
	ldd	CursorPos		; save current cursor pos
	std	SaveCursorPos
	
ToggleModeLoop1
	ldd	SaveCursorPos		; restore cursor pos
	std	CursorPos
	lbsr	ClrEOL			; clear to end of line
	
	ldb	#$01			; clear line 1
	lbsr	LCDClearLine
	
	ldd	2,u			; offset of message
	anda	#$7F			; mask out write bit
	leax	AY0,pcr			; base of message table
	leax	d,x			; add offset
	lbsr	DevWriteStr		; write it to screen / LCD
	
CallToggle	
	bsr	DoToggle		; toggle it & scan for buttons

	pshs	a			; save button bitmap
	
	lda	#ButtonNext		; Is next pressed ?
	anda	,s			; check it
	bne	ToggleModeExit		; yes, exit ToggleMode
	
	lda	#ButtonS3		; is S3 pressed?
	anda	,s			; check it
	bne	NextEntry
	
	lda	#ButtonS4		; is S4 pressed?
	anda	,s			; check it
	bne	PrevEntry
	
	leas	1,s			; drop saved buttons
	bra	CallToggle		; do nothing, keep toggling

NextEntry
	leau	4,u			; Entries are 4 bytes long
	ldx	2,u			; get string address
	cmpx	#TTerminator		; End of list?
	bne	ContinueToggle		; no, loop for more
	
	leau	ToggleList,pcr		; point to beginning of list

ContinueToggle
	leas	1,s			; drop saved buttons
	bra	ToggleModeLoop1		; loop for more
	
PrevEntry
	leau	-4,u			; Entries are 4 bytes long
	ldx	2,u			; get string address
	cmpx	#TTerminator		; End of list?
	bne	ContinueToggle		; no, loop for more
	
	leau	ToggleListTerm,pcr	; point past end of list
	leau	-4,u			; back one entry
	bra	ContinueToggle		; loop for more
		
ToggleModeExit
	puls	a,cc,pc			; restore and return
	
DoToggle
	clrb				; clear counter
	ldx	,u			; Get address to access

DoToggleRW
	tst	2,u			; get R/W bit
	bmi	DoToggleWLoop		; if set write to that address
	
DoToggleRLoop
	lda	,x			; access the address......
	decb				; decrement count
	bne	DoToggleRLoop		; loop until zero
	bra	DoTogglePoll		; poll buttons
	
DoToggleWLoop
	sta	,x			; access the address......
	decb				; decrement count
	bne	DoToggleWLoop		; loop until zero
	
DoTogglePoll	
	lda	Buttons			; Are any buttons being pressed?
	anda	#ButtonMask		; ignore non button bits
	beq	DoToggleRW		; none down continue toggling
	
	pshs	a			; save buttons

ToggleWaitUp	
	lda	Buttons			; get buttons
	anda	#ButtonMask		; ignore non button bits
	bne	ToggleWaitUp		; wait till released
	
	puls	a,pc			; restore and return
	
	
TTerminator	EQU	$FFFF	
WFlag		EQU	$8000		; write flag
; Table consists of entries each of 2 words, first is the address to access
; second is the offset of the name of the test, zero terminated
; note terminator at both ends is *REQUIRED*
	FDB	TTerminator,TTerminator	; terminator
ToggleList
	FDB	$0000,(AY0-AY0)		; RAM read $0000, bank0
	FDB	$1000,(AY0A-AY0)	; RAM read $1000, bank 1 for 4K rams
	FDB	$4000,(AY0B-AY0)	; RAM read $4000, bank 1 for 16K rams
	FDB	$8000,(AY1-AY0)		; ROM $8000-$9FFF
	FDB	$A000,(AY2-AY0)		; ROM $A000-$BFFF
	FDB	TriggerCTS,(AY3-AY0)	; ROM $C000-$FEFF
	FDB	$FF00,(AY4-AY0)		; PIA0
	FDB	$FF20,(AY5-AY0)		; PIA1
	FDB	TriggerP2,(AY6-AY0)	; I/O2
	FDB	$0000,WFlag+(AY7-AY0)	; RAM write $0000, bank0
	FDB	$1000,WFlag+(AY7A-AY0)	; RAM write $1000, bank 1 for 4K rams
	FDB	$4000,WFlag+(AY7B-AY0)	; RAM write $4000, bank 1 for 16K rams
ToggleListTerm
	FDB	TTerminator,TTerminator	; terminator

NoToggle	EQU	(ToggleListTerm-ToggleList)/4

AY0	FCN	"RAMR $0000 (Y0)"
AY0A	FCN	"RAMR $1000 (Y0)"
AY0B	FCN	"RAMR $4000 (Y0)"
AY1	FCN	"ROM  $8000 (Y1)"	
AY2	FCN	"ROM  $A000 (Y2)"	
AY3	FCN	"ROM  $C000 (Y3)"
AY4	FCN	"PIA0 $FF00 (Y4)"
AY5	FCN	"PIA1 $FF20 (Y5)"
AY6	FCN	"I/O  $FF40 (Y6)"
AY7	FCN	"RAMW $0000 (Y7)"
AY7A	FCN	"RAMW $1000 (Y7)"
AY7B	FCN	"RAMW $4000 (Y7)"

;		 123456789012345678901234 56789
ToggleLine
	FCN	"Toggling line: "
	
