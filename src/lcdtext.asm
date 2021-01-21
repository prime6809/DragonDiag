;
; Text messages for LCD.
;

;			          111111111122222  	
;			 123456789012345678901234 56789
LCDSignon	FCC	"Dragon/CoCo Diag Cart"  
		FCB	CR
		FCN	"Version 1.30"

LBuildDate	FCC	"Software build date :"
		FCB	CR,0

LScreenRAM	FCC	'Testing VDG RAM.....'
		FCB	CR,0
	
LMessRamTest	FCN	'Testing RAM:$'

LMessRamTestB	FCN	'Testing RAM block:$'

LTestValue	FCN	'Test value:$'
		
LMessFailedAt	FCB	CR
		FCN	'Failed at:$'
		
LPassed		FCB	CR
		FCN	'Passed.                '

LAddr07Test	FCN	'Address 0..7 test '
		
LAddr9FTest	FCN	'Address 9..F test '

LMessCSum80	FCN	'ROM:$8000 checksum:$'
		
LMessCSumA0	FCN	'ROM:$A000 checksum:$'

LMessCSumC0	FCN	'ROM:$C000 checksum:$'
		
LMessCSumE0	FCN	'ROM:$E000 checksum:$'

LCorrect	FCN	' Correct location'

LWrong		FCN	' Wrong location'

;			          111111111122222  	
;			 123456789012345678901234 56789
LPIATest	FCN	'PIA Register test.'

LPIA0Mess	FCN	'PIA0 '
		
LPIA1Mess	FCB	CR
		FCN	'PIA1 '

LACIAMess	FCN	'ACIA '

LPIA2Mess	FCN	'PIA2  '

LMessBeginLong	FCC	'Begin long RAM tests'
		FCB	CR,0
		
LMessD64	FCN	'Begin Dragon 64 tests.'

LMessD64End	FCN	'End Dragon 64 tests.'

LMess64K	FCC	'Begin upper RAM tests'
		FCB	CR,0
		
LMachineConf	FCC	'Configured machine :'
		FCB	CR,0

; Table of pointers to machine names, and RAM chip types
LModelTableD	FDB	LDragon
		FDB	LD32		
		FDB	LD64
		FDB	LDAlpha
		FDB	LInvalid
		
		
LModelTableC	FDB	LCoCo
		FDB	LCoCo12		
		FDB	LCoCo3
		FDB	LCoCo2b
		FDB	LInvalid
		
		
LRAMTable	FDB	L4K
		FDB	L16K
		FDB	L64K
		FDB	LStatic
		
LDragon		FCN	'Dragon'		
LD32		FCN	' 32'
LD64		FCN	' 64'
LDAlpha		FCN	' Alpha'
LInvalid	FCN	' Unknown'	

LCoCo		FCN	'CoCo'
LCoCo12		FCN	' 1/2'
LCoCo3		FCN	' 3'
LCoCo2b		FCN	' 2b'		

L4K		FCN	' 4K'
L16K		FCN	' 16K'
L64K		FCN	' 64K'
LStatic		FCN	' Static'

LIntsEnable	FCC	'Enabling Interrupts'
		FCB	CR,0
		
LSpuriousNMI	FCC	' Spurious NMIs'
		FCB	CR,0

LSpuriousFIRQ	FCN	' Spurious FIRQs'

LWaitNMI	FCN	'Wait NMI '
LWaitFIRQ	FCN	'Wait FIRQ '
LWaitP2		FCN	'P2 '
LWaitCTS	FCN	'CTS '

LTriggered	FCN	'Triggered'
LTimeout	FCN	'Timeout'

LPass		FCN	'Pass '
LFail		FCN	'Fail '

LCartTest	FCC	'Cartridge signal test'
		FCB	CR,0

;			          111111111122222  	
;			 123456789012345678901234 56789
LCartError	FCN	'Err Cart line stuck:'
		
LComplete	FCC	'All tests complete'
		FCB	CR
		FCN	'Press NEXT to retest.' 
		
;			          111111111122222  	
;			 123456789012345678901234 56789
LProbeDPlus	FCC	'Probe for Dragon Plus '
		FCB	CR,0

LProbeNotFound	FCC	'Not '
LProbeFound	FCN	'Found'	

LDPlusVRTest	FCC	'Dragon Plus RAM tests'
		FCB	CR,0

LCPUIs		FCN	' CPU:'
LCPU6809	FCN	'6809'
LCPU6309	FCN	'6309'

	