//---------------------------------------------------//
//
// The module has the following memory-mapped registers
//
//      N     16-bit  write-only  address A0 (= byte address 140)
//      D     16-bit  write-only  address A1 (= byte address 142)
//      Cin   1-bit   write-only  address A2 (= byte address 144)
//      Q     16-bit  read-only   address A3 (= byte address 146)
//      R      8-bit  read-only   address A4 (= byte address 148)
//      Cout  1-bit   read-only   address A5 (= byte address 14A)
//
// The SOFTWARE driver (on MSP) will drive this interface as follows
//
//     while (1) {
//         *N = numerator;
//         *D = divisor
//
//         SYNC1;
//
//         start computing
//         wait for result to finish
//         update Q and R
//
//         SYNC0;
//
//         quotient = *Q
//         remainder = *R;
//     }
//
//     Where SYNC1:  
//          *Cin = 1;  while (*Cout != 1) ;
//     and SYNC0:
//          *Cin = 0;  while (*Cout != 0) ;
//
// This HARDWARE module will perform the following operations in
// response to this software driver:
//
//     while (1) {
//
//          SYNC1s;
//
//          divider.N = N;
//          divider.D = D;
//          
//          start computing
//          until done
//
//          Q = divider.Q
//          R = divider.R
//
//          SYNC0s;
//
//     }
//
//     Where SYNC1s:  
//          While (*Cin != 1) ;
//          *Cout = 1;
//
//     Where SYNC0s:  
//          While (*Cin != 0) ;
//          *Cout = 0;

module  mydivider ( 
		    output [15:0] per_dout,
		    input 	  mclk,
		    input [13:0]  per_addr,
		    input [15:0]  per_din,
		    input 	  per_en,
		    input [1:0]   per_we,
		    input 	  puc_rst
		    );
   
   reg 				  reg_cin;         // memory mapped reg Cin   
   reg [15: 0] 			  reg_N;           // memory-mapped numerator register
   reg [15: 0] 			  reg_D;           // memory-mapped demoninator register 
   
   reg [ 2: 0] 			  reg_state, nxt_state;  // FSM state register
   
   reg 				  fsm_cout;        // FSM output (signal)
   
   localparam waitsync1s = 3'd0, gocompute = 3'd1, waitsync0s = 3'd2;

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
   
   assign per_dout   = read_Q    ? reg_N :
		       read_R    ? reg_D :
		       read_Cout ? {15'h0, fsm_cout} :
		       16'h0;
   
   always @*
     begin
        nxt_state = reg_state;
	fsm_cout  = 1'b0;	
	case (reg_state)
	  waitsync1s:
            begin 
               fsm_cout  = 1'b0;
	       nxt_state = reg_cin ? gocompute : waitsync1s;
            end
	  gocompute: 
	    begin
               fsm_cout  = 1'b1;
	       nxt_state = waitsync0s;
	    end
	  waitsync0s: 
            begin
               fsm_cout  = 1'b1;
	       nxt_state = ~reg_cin ? waitsync1s : waitsync0s;
            end
	endcase   
     end
   
endmodule

