;
; Text messages for VDG.
;

MessRamTest	FCC	'TESTING RAM:$'
		FCB	0
		
MessPassed	FCC	'PASSED'
		FCB	CR,0

MessFailedAt	FCB	CR
		FCC	'FAILED AT:$'
		FCB	0

MessWrote	FCC	' WR:$'
		FCB	0

MessRead	FCC	' RD:$'
		FCB	0
	
;MessCSum80	FCC	'ROM:$8000 CHECKSUM:$'
;		FCB	0

;MessCSumA0	FCC	'ROM:$A000 CHECKSUM:$'
;		FCB	0
				
MessPA		FCC	'D:.. C:.. R:.. D:.. C:.. R:.. '
		FCB	0			

MessD64		FCB	CR
		FCC	'BEGIN DRAGON 64 TESTS.'
		FCB	CR,0

MessOK	FCN	' OK'

MessNO	FCN	' NO'