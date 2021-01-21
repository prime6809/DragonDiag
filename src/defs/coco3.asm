;
; CoCo3 specific defines.
;

InitReg1	EQU	$FF90		; initialization register 1

Init1CoCo	EQU	%10000000	; CoCo 1/2 compatible mode
Init1MMU	EQU	%01000000	; MMU enable
Init1GIRQ	EQU	%00100000	; GIME IRQ enabled
Init1GFIRQ	EQU	%00010000	; GIME FIRQ enabled
Intit1RFE	EQU	%00001000	; Ram at FExx constant
Init1SCS	EQU	%00000100	; Standard P2/SCS
Init1MC1	EQU	%00000010	; ROM map control bit 1
Init1MC0	EQU	%00000001	; ROM map control bit 0

; Rom types for Init1MC0, Init1MC1
Init1ROMIntExt	EQU	%00000000	; 16K internal, 16K external (like CoCo 1,2)
IntitROMInt	EQU	%00000010	; 32K internal
IntitROMExt	EQU	%00000011	; 32K external (except interrupt vectors).

Init1ROMMask	EQU	Init1MC1+Init1MC0	; Mask for ROM bits

InitReg2	EQU	$FF91		; Initialization register 2

; bits 7,6,4,3,2,1 unused
Init2TINS	EQU	%00100000	; Timer input select, 1 = 70ns, 0 = 63.5 ns
Init2Task	EQU	%00000001	; Task register select

IRQEnableReg	EQU	$FF92		; Interrupt request enable register

; bits 7, 6 unused
IRQEnTMR	EQU	%00100000	; Timer interrupt
IRQEnHBORD	EQU	%00010000	; Horizontal border interrupt
IRQEnVBORD	EQU	%00001000	; Vertical border interrupt
IRQEnEI2	EQU	%00000100	; Serial data interrupt
IRQEnEI1	EQU	%00000010	; Keyboard interrupt
IRQEnEI0	EQU	%00000001	; Cartridge interrupt

FIRQEnableReg	EQU	$FF93		; Fast Interrupt request enable register

; bits 7, 6 unused
FIRQEnTMR	EQU	%00100000	; Timer interrupt
FIRQEnHBORD	EQU	%00010000	; Horizontal border interrupt
FIRQEnVBORD	EQU	%00001000	; Vertical border interrupt
FIRQEnEI2	EQU	%00000100	; Serial data interrupt
FIRQEnEI1	EQU	%00000010	; Keyboard interrupt
FIRQEnEI0	EQU	%00000001	; Cartridge interrupt

TimerMSB	EQU	$FF94		; High order bits of timer (bits 7..4 unused).
TimerLSB	EQU	$FF95		; Low order bits of timer

VideoReg	EQU	$FF98		; Video register

; bit 6 unused
VideoBP		EQU	%10000000	; Bitplane 0 = text modes, 1 = graphics modes
VideoBPI	EQU	%00100000	; Burst phase invert (colour set)
VideoMOCH	EQU	%00010000	; Monochrome on composite (when 1)
VideoH50	EQU	%00001000	; 1 = 50Hz power, 0 = 60Hz power
VideoLPRMask	EQU	%00000111	; Lines per row (see below)

VideoLPR1	EQU	%00000000	; One line per row
VideoLPR2	EQU	%00000001	; Two lines per row
VideoLPR3	EQU	%00000010	; Three lines per row
VideoLPR8	EQU	%00000011	; Eight lines per row
VideoLPR9	EQU	%00000100	; Nine lines per row
VideoLPR10	EQU	%00000101	; Ten lines per row
VideoLPR12	EQU	%00000110	; Twelve lines per row
VideoLPRRes	EQU	%00000111	; Reserved

; bit 7, undefined
; bits 6..5 Lines per field (number of rows)
; bits 4..2 Horizontal resolution
; bits 1..0 Colour resolution
VideoResReg	EQU	$FF99		; video resolution register

VidLPFMask	EQU	%01100000
VidLPF192	EQU	%00000000	; 192 rows
VidLPF200	EQU	%00100000	; 200 rows
VidLPF210	EQU	%01000000	; 210 rows
VidLPF225	EQU	%01100000	; 225 rows

VidHRESMask	EQU	%00011100	
VidHRES160	EQU	%00011100	; 160 graphics / 80 text
VidHRES128	EQU	%00011000	; 128 graphics / 64 text
VidHRES80	EQU	%00010100	; 80 graphics / 80 text
VidHRES64	EQU	%00010000	; 64 graphics / 64 text
VidHRES40	EQU	%00001100	; 40 graphics / 40 text
VidHRES32	EQU	%00001000	; 32 graphics / 32 text
VidHRES20	EQU	%00000100	; 20 graphics / 40 text
VidHRES16	EQU	%00000000	; 16 graphics / 32 text

; bits 7,6 unused, bits 5..0 contain border colour.
BorderReg	EQU	$FF9A		; Border register

; bits 7..4 reserved, bits 3..0 vertical scroll bits
VScrollReg	EQU	$FF9C		; vertical scroll register

VertOffsetMSB	EQU	$FF9D		; Vertical offset MSB
VertOffsetLSB	EQU	$FF9E		; Vertical offset LSB

HOffsetReg	EQU	$FF9F		; horizontal offset register

MMUBase		EQU	$FFA0		; base of MMU regs
MMUT0Base	EQU	MMUBase+0	; Base of Task 0 registers
MMUT1Base	EQU	MMUBase+8	; Base of Task 1 registers

MMUT0Block0	EQU	MMUT0Base+0	; task 0, block 0
MMUT0Block1	EQU	MMUT0Base+1	; task 0, block 1
MMUT0Block2	EQU	MMUT0Base+2	; task 0, block 2
MMUT0Block3	EQU	MMUT0Base+3	; task 0, block 3
MMUT0Block4	EQU	MMUT0Base+4	; task 0, block 4
MMUT0Block5	EQU	MMUT0Base+5	; task 0, block 5
MMUT0Block6	EQU	MMUT0Base+6	; task 0, block 6
MMUT0Block7	EQU	MMUT0Base+7	; task 0, block 7

MMUT1Block0	EQU	MMUT1Base+0	; task 1, block 0
MMUT1Block1	EQU	MMUT1Base+1	; task 1, block 1
MMUT1Block2	EQU	MMUT1Base+2	; task 1, block 2
MMUT1Block3	EQU	MMUT1Base+3	; task 1, block 3
MMUT1Block4	EQU	MMUT1Base+4	; task 1, block 4
MMUT1Block5	EQU	MMUT1Base+5	; task 1, block 5
MMUT1Block6	EQU	MMUT1Base+6	; task 1, block 6
MMUT1Block7	EQU	MMUT1Base+7	; task 1, block 7

; MMU blocks
; For a basic 128K CoCo3, the 128K occupies the *TOP* 128K of the
; virtual address space.
; Bits 5..3 determine the block number, bits 2..0 determine the 8K
; page within the block.

Block60		EQU	$30
Block61		EQU	$31
Block62		EQU	$32
Block63		EQU	$33
Block64		EQU	$34
Block65		EQU	$35
Block66		EQU	$36
Block67		EQU	$37

Block70		EQU	$38
Block71		EQU	$39
Block72		EQU	$3A
Block73		EQU	$3B
Block74		EQU	$3C
Block75		EQU	$3D
Block76		EQU	$3E
Block77		EQU	$3F

MinBlock128	EQU	$30
MinBlock512	EQU	$00
MaxBlock	EQU	$3F
MaxBlockRRMode	EQU	$3B		; Maximimum RAM block if ROM enabled.

BlockNoMask	EQU	$3F

Block0Base	EQU	$0000		; $0000-$1FFF
Block1Base	EQU	$2000		; $2000-$1FFF
Block2Base	EQU	$4000		; $4000-$1FFF
Block3Base	EQU	$6000		; $6000-$1FFF
Block4Base	EQU	$8000		; $8000-$1FFF
Block5Base	EQU	$A000		; $A000-$1FFF
Block6Base	EQU	$C000		; $C000-$1FFF
Block7Base	EQU	$E000		; $E000-$1FFF


PaletteBase	EQU	$FFB0		; base of palette registers
Palette0	EQU	PaletteBase+0
Palette1	EQU	PaletteBase+1
Palette2	EQU	PaletteBase+2
Palette3	EQU	PaletteBase+3
Palette4	EQU	PaletteBase+4
Palette5	EQU	PaletteBase+5
Palette6	EQU	PaletteBase+6
Palette7	EQU	PaletteBase+7
Palette8	EQU	PaletteBase+8
Palette9	EQU	PaletteBase+9
Palette10	EQU	PaletteBase+10
Palette11	EQU	PaletteBase+11
Palette12	EQU	PaletteBase+12
Palette13	EQU	PaletteBase+13
Palette14	EQU	PaletteBase+14
Palette15	EQU	PaletteBase+15
