#
# Makefile for Dragondos rom.
#
# 21/11/2004, P.Harvey-Smith.
#

AS=lwasm
ASFLAGS=-9 -r -I defs

ZIP=pkzip
RM=rm
ASMTIME=asmdatetime

all: diagd diagm buildrom

# Diag cart, Dragon
diagd: DiagCart.asm
		$(ASMTIME) -6809 > datetime.asm	
		$(AS) $(ASFLAGS) -DDragon -oroms/DiagDragon.rom -llist/DiagDragon.lst DiagCart.asm 

# Diag cart, Tandy CoCo
#diagt: DiagCart.asm
#		$(AS) $(ASFLAGS) -DTandy -oroms/DiagCoCo.rom -llist/DiagTandy.lst DiagCart.asm 

# Diag cart, Tandy CoCo
diagm: DiagCart.asm
		$(AS) $(ASFLAGS) -DDragon -DTest -oroms/DiagMame.rom -llist/DiagMame.lst DiagCart.asm 

	
clean:
		$(RM) -f roms/*.rom
		$(RM) -f list/*.lst
		
buildrom:
		cp ../DDDiag/roms/dddiagd.rom roms
		cp ../DDDiag/roms/dddiagc.rom roms
		os9 padrom -c=$ff 16384 roms/dddiagd.rom
		os9 padrom -c=$ff 16384 roms/dddiagc.rom
		
		cat roms/DiagDragon.rom roms/dddiagd.rom roms/dddiagc.rom > roms/DiagROM.rom
		
		cp roms/DiagDragon.rom roms/DIAGDGN.ROM