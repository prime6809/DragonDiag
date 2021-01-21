;
; CPUDEFS
;

; bitmasks for flags
FlagCarry		equ		$01
FlagOverflow	equ		$02
FlagZero		equ		$04
FlagNegative	equ		$08
FlagIRQ			equ		$10
FlagHlafCarry	equ		$20
FlagFIRQ		equ		$40
FlagEntire		equ		$80

; ANDCC with IntsEnable to enable IRQ + FIRQ
; ORCC with IntsDisable to disable IRQ + FIRQ
IntsEnable		equ		~(FlagFIRQ+FlagIRQ)
IntsDisable		equ		(FlagFIRQ+FlagIRQ)	

HWVecBase		equ		$FFF2
HWVecSWI3		equ		$FFF2
HWVecSWI2		equ		$FFF4
HWVecFIRQ		equ		$FFF6
HWVecIRQ		equ		$FFF8
HWVecSWI		equ		$FFFA
HWVecNMI		equ		$FFFC
HWVecReset		equ		$FFFE

HWVecCount		equ		$7




