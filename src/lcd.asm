;
; LCD driver for standard character Hitachi HD44780 based LCD modules.
;

; Constants borrowed from AVR source


LCDCmdClear		equ	0x01	; Clear screen
LCDCmdCursorHome	equ	0x02	; Cursor home

LCDCmdEntryModeSet	equ	0x04	; Set entry mode, 
LCDCmdEntryI		equ	0x02	; Combine with EntryModeSet, 1 cursor moves right, 0 cursor moves left
LCDCmdEntryS		equ	0x01	; Combine with EntryModeSet, 1=shift display as I, 0 don't shift display

LCDCmdEntryModeSetI	equ	LCDCmdEntryModeSet+LCDCmdEntryI
LCDCmdEntryModeSetIS	equ	LCDCmdEntryModeSetI+LCDCmdEntryS
LCDCmdEntryModeSetS	equ	LCDCmdEntryModeSet+LCDCmdEntryS

LCDCmdDisplay		equ	0x08	; Turn display off
LCDCmdDispDisp		equ	0x04	; Display on 1 / off 0
LCDCmdDispCurs		equ	0x02	; Cursor on 1 / off 0
LCDCmdDispBlink		equ	0x01	; Blink on 1 / off 0

LCDCmdDisplayOn		equ	LCDCmdDisplay+LCDCmdDispDisp		; Display on
LCDCmdDisplayOnCurs	equ	LCDCmdDisplayOn+LCDCmdDispCurs		; Display on with cursor
LCDCmdDisplayOnCursBnk	equ	LCDCmdDisplayOnCurs+LCDCmdDispBlink	; Display on with blinking cursor

LCDCmdShiftCursLeft	equ	0x10	; Shift cursor left
LCDCmdShiftCursRight	equ	0x14	; Shift cursor right
LCDCmdShiftDispLeft	equ	0x18	; Shift display left
LCDCmdShiftDispRight	equ	0x1C	; Shift display right

; The set data length and no lines must be ored together before sending

LCDCmdSetDataLen4	equ	0x20	; Set data length 4 bit
LCDCmdSetDataLen8	equ	0x30	; Set data length 8 bit
LCDCmdLines1		equ	0x00	; Set 1 line mode
LCDCmdLines2		equ	0x08	; Set 2 line mode

; CG address functions must be ored with 6 bit address to set
; DD address functions must be ored with 7 bit address to set

LCDCmdCGRamAddrSet	equ	0x40	; Set Character generator address
LCDCmdDDRamAddrSet	equ	0x80	; Set Data ram address

LCDBusyFlagMask		equ	0x80	; Mask for busy flag

LCDLineLen		equ	24	; LCD line length
LCDNoLines		equ	2	; LCD no of lines

LCDInit		clr	LCDFlag		; Flag LCD not in use

		ldx	#0		; init counter
LCDInitLoop	lda	LCDCmdStat	; get status flag
		bpl	LNotBusy	; if bit 7 is clear it's not busy
		
		leax	1,x		; increment wait counter
		bne	LCDInitLoop	; keep looping if not 0
		
		rts			; return leaving LCD flagged not in use

; Try to INIT the LCD by software
LCDInit2	clr	LCDFlag		; Flag LCD not in use
		ldb	#LCDCmdSetDataLen8	; function set

		lda	#3		; send it 3 times
		
LCDInit2Loop	bsr	LCDDelay	; Delay a little after poweron
		stb	LCDCmdStat	; send the command
		
		deca			; decrement count
		bne	LCDInit2Loop	; loop again if not zero

		bra	LCDInit		; jump to normal init loop
		
LCDDelay	ldx	#$1000		; delat loop counter
LCDDelayLoop	leax	-1,x		; decrement counter
		bne	LCDDelayLoop	; loop until zero
		rts
				
LNotBusy	dec	LCDFlag		; mark LCD available

		lda	#DevLCD		; select LCD as output device
		ora	OutputFlag
		sta	OutputFlag
	
		ldb	#LCDCmdSetDataLen8+LCDCmdLines2	; 8 bit data 2 display lines
		bsr	LCDCommand

		ldb	#LCDCmdEntryModeSetI
		bsr	LCDCommand
		
		ldb	#LCDCmdDisplayOnCursBnk ; turn display on
		bsr	LCDCommand
		
		ldb	#LCDCmdShiftCursLeft
		bsr	LCDCommand
		
		bsr	LCDClrScr	; clear the screen
		
		rts

;
; LCD Comamnd
;
; Send command in B to LCD.
;

LCDCommand	tst	LCDFlag		; Is LCD available?		
		beq	LCDExit		; nope....
		
		stb	LCDCmdStat	; send the command
		
LCDCmdWait	tst	LCDCmdStat	; Wait for it to complete
		bmi	LCDCmdWait	; b7 set if busy
		rts	

;
; For convenience.......
;

LCR		lda	#CR		; carrige return
		fcb	Skip2		; skip 2 bytes

LSpace		lda	#' '		; space character
		fcb	Skip2		; skip 2 bytes
		
LDash		lda	#'-'		; dash character
		fcb	Skip2		; skip 2 bytes
		
LDollar		lda	#'$'		; write a dollar char
		
;
; Write character in A to LCD.
;
		
LCDWriteChar	tst	LCDFlag		; Is LCD available?		
		beq	LCDExit		; nope....
		
		cmpa	#CR		; EOL?
		beq	LCDNewLine	; yes do a newline
		
		sta	LCDData		; send the data

LCDCharLoop	tst	LCDCmdStat	; Wait for it to become free again
		bmi	LCDCharLoop
		
LCDExit		rts		

;
; LCDWriteStr, write a zero terminates string from X
;

LCDWriteStr	pshs	a		; save a
LCDWriteStrLoop	lda	,x+		; get character from string
		beq	LCDWriteStrExit	; exit if null
		
		bsr	LCDWriteChar	; write it
		bra	LCDWriteStrLoop	; write next

LCDWriteStrExit	puls	a,pc		; restore and return
;
; LCDGotoXY
;
; Entry:
;	A	= X co-ordinate
;	B	= Y co-ordinate
;
LCDGotoXY	pshs	a	
		andb	#$03		; Max line no is 4....
		stb	LCDLineNo	; update line number

		lda	#$40		; 
		mul			; result will be in b anyway.....
		addb	,s+		; add X co-ordinate
		addb	#LCDCmdDDRamAddrSet	; the command
		
		bsr	LCDCommand	; send it
		rts

LCDNewLine	pshs	d
		ldb	LCDLineNo	; get line number
		cmpb	#LCDNoLines-1	; greater than max LineNo?
		bhs	NoNewLine	; yes, don't update
		
		incb			; increment it
		stb	LCDLineNo	; update line no
		
NoNewLine	clra			; X=0
		bsr	LCDGotoXY	; move cursor
		puls	d,pc		; restore and return		
		
		
;
; LCDClrScr, clear the screen
;

LCDClrScr	pshs	d

		ldb	#LCDCmdClear	; Clear screen command
		bsr	LCDCommand
		
		ldd	#$0000		; X,Y=0,0
		bsr	LCDGotoXY
		
LCDClrScrExit	puls	d,pc		; restore and return
		

LCDSet		pshs	a		; save a
		lda	OutputFlag	; get output flag
		sta	OldOutputFlag	; save it
		lda	#DevLCD		; LCD.....
		sta	OutputFlag	
		puls	a,pc		; restore and return
		
;
; LCD hex routines
;

LCDHexByte	bsr	LCDSet		; set to LCD only
		lbsr	DevHexByte	; call hex routine
		lbra	OutputReset	; Reset output byte
		
LCDHexWord	bsr	LCDSet		; set to LCD only
		lbsr	DevHexWord	; call hex routine
		lbra	OutputReset	; Reset output byte
		
LCDPrintBuff	pshs	x		; save x
		ldx	#PrintBuff	; point at print buffer 
		lbsr	LCDWriteStr	; go write it
		puls	x,pc		; restore and return

		
;
; Display 'Passed' message on LCD, wait for a short delay.
;		
		
LCDPassed	leax	LPassed,pcr	; point at message
		bsr	LCDWriteStr	; write it
		lbsr	Wait		; delay loop
		rts
		
;
; Clear screen and display message pointed to by X
;		

LCDClrWriteStr	bsr	LCDClrScr	; clear screen
		bra	LCDWriteStr	; and write the string
		
LCDClrWriteStrWait
		bsr	LCDClrWriteStr	; clear screen, write string
		lbra	WaitPause	; and then wait

LCDClrWriteStrWaitB
		bsr	LCDClrWriteStr	; clear screen, write string
		lbra	WaitB		; and then wait
		
;
; B= line to clear
;
LCDClearLine
	pshs	b			; Save line no
	clra				; for gotoxy
	bsr	LCDGotoXY		; move to that line
	ldb	#40			; 40 characters / line
		
LCDClearLineLoop
	lbsr	LSpace			; write a space
	decb				; decrement count
	bne	LCDClearLineLoop	; loop until done
	
	puls	b			; restore lineno
	clra				; col 0
	lbra	LCDGotoXY