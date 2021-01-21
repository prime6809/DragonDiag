# DragonDiag
Diagnotic card for the Dragon 32/64 and Tandy CoCo 1,2,3.

Included is the Hardware design files created in Eagle, these should be 
compatible with any version of Eagale 6.x or later. Recent versions of 
KiCad should also be able to successfully import them.

The Verilog source for the onboard XC95144XL CPLD. This can be built with
Xilinx WebPack 14.7.

The 6809 source to the diagnostic ROM generally programed into the first 
8K of the onboard flash rom. To assemble this you will need lwasm available
from http://www.lwtools.ca/ You will also need a nnix compatible make utility
I generally use cygwin, but it should be builable under Linux / Macos or 
any unix like environment with the correct tools.


