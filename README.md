# hw5-ece4530-f17-samplesolution

## msp430de

This is a loopback design that demonstrates the synchronization protocol between software and hardware

- Software: msp430de/software/functionaltest
- Hardware: msp430de/hardware/msp430de1soc/msp430/mydivider.v

## msp430de_div

This is a complete design that integrates the divider and the the synchronization protocol between software and hardware

- Software: msp430de_div/software/functionaltest
- Hardware: msp430de_div/hardware/msp430de1soc/msp430/mydivider.v and msp430de_div/hardware/msp430de1soc/msp430/mydivider.v 

## main.c driver

```
// REGISTERS
#define NN        (*(volatile unsigned *)      0x140)
#define DD        (*(volatile unsigned *)      0x142)
#define CIN       (*(volatile unsigned *)      0x144)
#define QQ        (*(volatile unsigned *)      0x146)
#define RR        (*(volatile unsigned *)      0x148)
#define COUT      (*(volatile unsigned *)      0x14A)

// master sync
void SYNC1() {
  CIN   = 1;
  while (COUT != 1) ;
}

void SYNC0() {
  CIN   = 0;
  while (COUT != 0) ;
}

void myintdiv(int _n, int _d, int *_q, int *_r) {

  NN = _n;
  DD = _d;
  
  SYNC1();

  SYNC0();
  
  *_q = QQ;
  *_r = RR;
}
```

## mydivider.v hardware divider interface

```
module  mydivider ( 
		    output [15:0] per_dout,
		    input 	      mclk,
		    input [13:0]  per_addr,
		    input [15:0]  per_din,
		    input 	      per_en,
		    input [1:0]   per_we,
		    input 	      puc_rst
		    );
   
   reg 				        reg_cin;         // memory mapped reg Cin   
   reg [15: 0] 			  reg_N;           // memory-mapped numerator register
   reg [15: 0] 			  reg_D;           // memory-mapped demoninator register 
   
   reg [ 2: 0] 			  reg_state, nxt_state;  // FSM state register
   
   reg 				        fsm_cout;        // FSM output (signal)

   wire [15:0] 			  div_N;
   wire [15:0] 			  div_D;
   wire 			        div_start;
   wire [7:0] 			  div_Q;
   wire [15:0] 			  div_R;
   wire 			        div_done;
   divider divider1(.clk(mclk), 
		    .reset(puc_rst),
		    .N(div_N),  
		    .D(div_D), 
		    .start(div_start), 
		    .Q(div_Q),
		    .R(div_R),
		    .done(div_done));

   assign div_D = reg_D;      // from memory mapped register
   assign div_N = reg_N;      // from memory mapped register
   reg 	startcmd;
   assign div_start = startcmd;  // computed in fsm
      
   localparam 
     waitsync1s = 3'd0, 
     gocompute = 3'd1, 
     continuecompute = 3'd2, 
     waitsync0s = 3'd3;

   wire 			  write_N;
   wire 			  write_D;
   wire 			  read_Q;
   wire 			  read_R;
   wire 			  write_Cin;
   wire 			  read_Cout;
   
   assign write_N   = (per_en & (per_addr == 14'hA0) &  per_we[0] &  per_we[1]);
   assign write_D   = (per_en & (per_addr == 14'hA1) &  per_we[0] &  per_we[1]);
   assign write_Cin = (per_en & (per_addr == 14'hA2) &  per_we[0] &  per_we[1]);
   
   assign read_Q    = (per_en & (per_addr == 14'hA3) & ~per_we[0] & ~per_we[1]);
   assign read_R    = (per_en & (per_addr == 14'hA4) & ~per_we[0] & ~per_we[1]);
   assign read_Cout = (per_en & (per_addr == 14'hA5) & ~per_we[0] & ~per_we[1]);
   
   always @(posedge mclk or posedge puc_rst)
     if (puc_rst == 1'h1)
       begin
	        reg_N     <= 16'h0;
	        reg_D     <= 16'h0;
	        reg_cin   <= 1'b0;
          reg_state <= waitsync1s;
       end
     else begin
	        reg_N       <= write_N   ? per_din       : reg_N;
	        reg_D       <= write_D   ? per_din       : reg_D;
	        reg_cin     <= write_Cin ? per_din[0]    : reg_cin;
          reg_state   <= nxt_state;
     end
   
   assign per_dout   = read_Q    ? {8'h0,div_Q} :
		       read_R    ? div_R :
		       read_Cout ? {15'h0, fsm_cout} :
		       16'h0;
   
   always @*
     begin
        nxt_state = reg_state;
	fsm_cout  = 1'b0;	
	startcmd = 1'b0;
	
	case (reg_state)
	  waitsync1s:
         begin 
           fsm_cout  = 1'b0;
	         nxt_state = reg_cin ? gocompute : waitsync1s;
         end
	  gocompute: 
	      begin
          fsm_cout  = 1'b1;
	        startcmd  = 1'b1;	       
	        nxt_state = continuecompute;
	      end
	  continuecompute:
	      begin
          fsm_cout  = 1'b1;
	        startcmd  = 1'b0;	       
	        nxt_state = (div_done) ? waitsync0s : continuecompute;
	      end
	  waitsync0s: 
        begin
          fsm_cout  = 1'b1;
	        nxt_state = ~reg_cin ? waitsync1s : waitsync0s;
        end
	  endcase   
  end
   
endmodule
```
