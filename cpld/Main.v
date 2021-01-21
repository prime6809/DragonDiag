`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:57:34 06/29/2011 
// Design Name: 
// Module Name:    Main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Main(
	// 6809 side
    input [15:0] Addr,		// Dragon address bus
    inout [7:0] Data,		// Daragon data bus
    input E,				// E clock
	input Q,				// Q clock
    input RW,				// Read/Write
    input CTS,				// Cart rom select 
    input P2,				// P2/SCS acrive from $ff40-$ff5f
    input Reset,			// System reset
	output DSD,				// Device select disable
    output FIRQ,			// Cart FIRQ
    output NMI,				// Non maskable interupt
    input HALT,				// Halt CPU
    
	// Onboard hardware
    output [7:0] LEDSOut,	// LEDS
	output [1:0] LEDS2Out,	// LEDS group 2
    input [3:0] DIPSw,		// DIP switches
	input [3:0] DIPC,		// Config DIP switches
	input [3:0] Buttons,	// toggle buttons
	
	output EDiv,			// E divider
	output QDiv,			// Q divider
	output HaltLED,			// nHALT indicator
	output ResetLED,		// nReset indicator
	
	// Memory control
    output nRD,				// Read strobe
    output nWR,				// Write strobe
    output nROMCS,			// ROM chip select
    output nRAMCS,			// RAM chip select
	
	// Disable remap button
	input DisableRemap,		// Disable remap button
	input AutoStart,		// Autostart jumper
	
	output LCDE				// Enable to the LCD
	
//	output [3:0] SP,		// spare outputs
	
//	output ROMA14,			// Additional lines to ROM
//	output ROMA15
		
	);

`define ChainWidth	3

	reg [7:0] LEDS;					// LEDS
	reg [1:0] LEDS2;				// LEDS group 2
	reg [`ChainWidth:0] EDivChain;	// Divider chain E
	reg [`ChainWidth:0] QDivChain;	// Divider chain Q
	reg IntDisable;					// If true don't ramap Int vectors

	reg	StatusReady;				// To flag system up and running
	reg	LatchCTS;					// Cartridge select seen
	reg LatchP2;					// P2 seen
	
	reg	[`ChainWidth:0] NMITimer;	// timer for triggering NMI
	reg NMICounting;				// is NMI timer counting 					
	reg	[`ChainWidth:0] FIRQTimer;	// timer for triggering FIRQ
	reg FIRQCounting;				// is FIRQ timer counting 	

	reg MapDisable;					// Decoding disabled, in map mode 1 (set by SAM writes)
	reg ROMDisable;					// Decoding disabled set by write to status reg bit
	
// Bits within status register	
`define ReadyBit	7
`define NMIBit		6
`define FIRQBit		5	
`define DisableBit	4
	

	// Generate OE and WE signals, only do this if Reset is high ! 
	assign RD			= E & RW & Reset;
	assign WR			= E & Q & ~RW & Reset;
	assign nRD			= ~RD;
	assign nWR			= ~WR;

//
// Address decoding and ROM/RAM banking control.
// 	
	// Address renages
	// Note Range ROM is 16 bytes short of the halfway mark, so we can check
	// for CTS being selected.
	assign RangeRAM		= ((Addr>=16'hE000) && (Addr<=16'hFEFF));
	assign RangeROM		= ((Addr>=16'hC000) && (Addr<=16'hDEF0));
	assign RangeIntVec	= ((Addr>=16'hFFF0) && (Addr<=16'hFFFF) && ~IntDisable);
	
	// Do not enable the RAM and ROM in MapMode 1 as motherboard RAM enabled then.
	// Do not enable RAM and ROM if Disable bit in Status set
	assign Disable		= MapDisable | ROMDisable;
	
	// Enable RAM in it's range if Disable is not set
	assign RAMCS		= RangeRAM & !Disable;
	assign nRAMCS		= ~RAMCS;

	// Enable ROM in it's ranges if Disable is not set
	assign ROMCS		= (RangeROM | RangeIntVec) & !Disable;
	assign nROMCS		= ~ROMCS;

	// Our I/O locations
	// Leds are split over 2 loacations, 8 in first, last two in second
	// Read and Write
	assign DragonLEDS	= (Addr==16'hff40);
	assign DragonLEDS2	= (Addr==16'hff41);
	
	// DIP switches 4 control and 4 machine/ram type select
	// 4 pushbuttons for interacting with the software
	// Reado only
	assign DragonDIP	= (Addr==16'hff42);
	assign DragonBTN	= (Addr==16'hff43);
	
	// Status register R/W
	// Status reset register
	assign DragonStatus	= (Addr==16'hff44);
	assign DragonStatR	= (Addr==16'hff45);
	
	// LCD, normally a 24x2. 
	assign DragonLCD	= ((Addr>=16'hff48) && (Addr<=16'hff49));
	assign DragonIO		= DragonLEDS | DragonLEDS2 | DragonDIP | DragonBTN | DragonStatus | DragonStatR;
	
	assign DragonIORD	= DragonIO & RD;
	assign DragonIOWR	= DragonIO & WR;
	
	assign LCDE			= (DragonLCD & E);	// LCD enable, active high
	
	assign DragonCTS	= ((Addr==16'hDEFF) & E & ~Q);	// CTS should be active here
	assign DragonP2		= ((Addr==16'hFF50) & E & ~Q);	// P2 should be active here
	
	// Reset status bits when writing to this location
	assign DragonStatRS	= (DragonStatR & DragonIOWR);

	// SAM map mode write, so we capture changes to the SAM RAM MAP mode
	assign MapMode		= ((Addr == 16'hFFDE) || (Addr == 16'hFFDF)) & WR;

	// When either of the SAM map mode bits is written we capture
	// the bit in A[0], as this is effectively the data bit.
	always @(negedge MapMode or negedge Reset)
	begin
	  if (!Reset)
		MapDisable <= 1'b0;
	  else
		MapDisable <= Addr[0];
	end

	// Disable internal device selection when our RAM, ROM or I/O is enabled.
	assign DSD			= ~((RAMCS | ROMCS | DragonIO) & E & ~Disable); // ? 1'b0 : 1'bz;
	
	// When the Dragon reads give it the contents of the LEDS, LEDS2, DIPS, Buttons, or Status
	// register registers as selected form it's address.
	wire [7:0] 	DragonDataOut;
	assign 	DragonDataOut[7:0]		= DragonLEDS 	? LEDS[7:0] : 
									  DragonLEDS2 	? {6'b0,LEDS2[1:0]} : 
									  DragonStatus	? {StatusReady,NMICounting,FIRQCounting,ROMDisable,LatchP2,LatchCTS,P2,CTS} : 
									  DragonBTN		? {4'b0, ~Buttons[3:0]} :	              
													  {~DIPC[3:0], ~DIPSw[3:0]};
	
	assign 	Data					= DragonIORD ? DragonDataOut : 8'bz;

	
	
	// Latch Dragon write to LEDS
	assign DragonLEDSWR		= (DragonLEDS & DragonIOWR);
	assign DragonLEDS2WR	= (DragonLEDS2 & DragonIOWR);
		
	always @(negedge DragonLEDSWR)
	begin
	  LEDS <= Data;
	end

	always @(posedge DragonLEDS2WR)
	begin
	  LEDS2[1:0] <= Data[1:0];
	end

	assign LEDSOut[7:0]		= ~LEDS[7:0];
	assign LEDS2Out[1:0]	= ~LEDS2[1:0];
		
	
	
	
	// Latch Dragon write to status
	assign DragonStatusWR	= (DragonStatus & DragonIOWR);
	
	always @(negedge DragonStatusWR or negedge Reset) 
	begin
	  if (!Reset)
	  begin
	    StatusReady <= 1'b0;
	    ROMDisable <= 1'b0;
	  end
	  else
	  begin
	    StatusReady <= Data[`ReadyBit];
	    ROMDisable <= Data[`DisableBit];
	  end
	end

	// generate signals to trigger stat of NMI and FIRQ counters
	assign NMICountStart	= DragonStatusWR & Data[`NMIBit];
	assign FIRQCountStart	= DragonStatusWR & Data[`FIRQBit];
		
	//
	// E and Q output divider chains.
	// 
	// We use these as they will indicate that the E and Q signals are actually
	// toggling rather than just being stuck high which a simple LED on E qnd Q
	// would not be able to.
	//
	
	always @(posedge E or negedge Reset)
	begin
	  if (!Reset)
	    EDivChain <= `ChainWidth'b0;
	  else
	    EDivChain <= EDivChain +1;
	end
	
	assign EDiv	= ~EDivChain[`ChainWidth];
	
	always @(posedge Q or negedge Reset)
	begin
	  if (!Reset)
	    QDivChain <= `ChainWidth'b0;
	  else
  	    QDivChain <= QDivChain +1;
	end
	
	assign QDiv	= ~QDivChain[`ChainWidth];
	
	// We latch this on reset, so that we can hold down the
	// disable button, hit reset and the machine will reboot into
	// normal mode. But will come back to diag mode on the next 
	// reset (where the button is not held down).
	always @(negedge Reset)
	begin
	  IntDisable <= ~DisableRemap;
	end
	
	
	// NMI Generator one shot
	// start the counter on a write of 1 to the status bit
	// stop the count after one NMI
	always @(posedge NMICountStart or posedge NMI)
	begin
	  if (NMICountStart)
	    NMICounting <= 1'b1;
	  else
		NMICounting <= 1'b0;
	end
	
	always @(posedge E)
	begin
	  if (~NMICounting)
	    NMITimer <= `ChainWidth'b0;
	  else	
	    NMITimer <= NMITimer+1;
	end
	
	assign NMI	= (NMITimer >= 4'hC) ? 1'b0 : 1'bz;
	
	// FIRQ generator
	always @(posedge FIRQCountStart or posedge FIRQ)
	begin
	  if (FIRQCountStart)
	    FIRQCounting <= 1'b1;
	  else
		FIRQCounting <= 1'b0;
	end
	
	always @(posedge E)
	begin
	  if (~FIRQCounting)
	    FIRQTimer <= `ChainWidth'b0;
	  else	
	    FIRQTimer <= FIRQTimer+1;
	end
	
	assign nAutoStart	= (~AutoStart & ~DisableRemap);			// it's active low, only active 
																// if disabling remap as well
	assign FIRQ	= nAutoStart ? Q :								// standard dragon cartridge	
				  (FIRQTimer == `ChainWidth'b1) ? 1'b0 : 1'bz;	// Our trigger
	

	// When the area where CTS is triggered is accessed, latch the access into
	// the bit in the status register. Clear that bit on a write to StatusStatRS
	always @(posedge DragonCTS or negedge DragonStatRS)
	begin
	  if (DragonCTS)
	    LatchCTS <= ~CTS;
	  else
	    LatchCTS <= 1'b0;
	end
	
	// When the area where P2 is triggered is accessed, latch the access into
	// the bit in the status register. Clear that bit on a write to StatusStatRS
	always @(posedge DragonP2 or negedge DragonStatRS)
	begin
	  if (DragonP2)
	    LatchP2 <= ~P2;
	  else
	    LatchP2 <= 1'b0;
	end
		
	
	// Note not inverted as LEDs are on when pin is LOW.
	assign HaltLED 	= HALT;
	assign ResetLED	= Reset;
	
	
	// Spare I/O pins currently unused.
//	assign SP[3:0]	= 4'bz;
endmodule
