//---------------------------------------------------//
//
// This module is a hardware-software interface
// between MSP430 and the mymax module. It uses req-ack
// handshake signals to translate memory-mapped register
// reading/writing into the required control and data 
// signals for the mymax module
//
// The module has the following memory-mapped registers
//
//      Din  16-bit  write-only  address A0 (= byte address 140)
//      Cin  1-bit   write-only  address A1 (= byte address 142)
//      Dout 16-bit  read-only   address A2 (= byte address 144)
//      Cout 1-bit   read-only   address A3 (= byte address 146)
//
// The module instantiates mymax
//    module mymax(clk, reset, step, Din, Dout);
//
// The SOFTWARE driver (on MSP) will drive this interface as follows
//
//     while (1) {
//         *Din = value1;
//         SYNC1;
//         *Din = value2;
//         SYNC0;
//         SYNC1;
//         result = *Dout;        
//         SYNC0; 
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
//          SYNC1s;
//          mymax.Din = Din; mymax.step = 1;  (for 1 cycle)
//          SYNC0s;
//          mymax.Din = Din; mymax.step = 1;  (for 1 cycle)
//          Dout = mymax.Dout; mymax.step = 1; (for 1 cycle)
//          SYNC1s;
//          SYNC0s;
//     }
//
//---------------------------------------------------//

module  mymax_msp ( 
           output [15:0] per_dout,
           input     mclk,
           input [13:0]  per_addr,
           input [15:0]  per_din,
           input     per_en,
           input [1:0]   per_we,
           input     puc_rst
           );
   
   reg [15: 0]  reg_din;               // memory mapped reg Din
   reg      reg_cin;               // memory mapped reg Cin
   
   reg [15: 0]  reg_max,   nxt_max;    // working register
   
   reg [ 2: 0]  reg_state, nxt_state;  // FSM state registers
   reg [15: 0]  fsm_dout;              // FSM output (signal)
   reg      fsm_cout;              // FSM output (signal)
   
   localparam S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3;
   
   wire  write_Din, write_Cin, read_Dout, read_Cout;  // memory decoding strobes
   assign write_Din = (per_en & (per_addr == 14'hA0) &  per_we[0] &  per_we[1]);
   assign write_Cin = (per_en & (per_addr == 14'hA1) &  per_we[0] &  per_we[1]);
   assign read_Dout = (per_en & (per_addr == 14'hA2) & ~per_we[0] & ~per_we[1]);
   assign read_Cout = (per_en & (per_addr == 14'hA3) & ~per_we[0] & ~per_we[1]);
   
   always @(posedge mclk or posedge puc_rst)
     if (puc_rst == 1'h1)
       begin
      reg_max   <= 16'h0;
      reg_din   <= 16'h0;
      reg_cin   <= 1'b0;
          reg_state <= S0;
       end
     else begin
    reg_max   <= nxt_max;
    reg_din   <= write_Din ? per_din[15:0] : reg_din;
    reg_cin   <= write_Cin ? per_din[0]    : reg_cin;
        reg_state <= nxt_state;
     end
   
   assign per_dout     = read_Dout ? fsm_dout : 
             read_Cout ? {15'h0, fsm_cout} :
             16'h0;
   
   always @*
     begin
    nxt_max   = reg_max;
        nxt_state = reg_state;      
    case (reg_state)
      S0: 
        begin // wait for SYNC1
           fsm_cout  = 1'b0;
           fsm_dout  = 16'h0;
           if (reg_cin) begin
          nxt_state = S1;
                  nxt_max   = reg_din;
               end
            end                
      S1: 
        begin // wait for SYNC0
           fsm_cout  = 1'b1;
           fsm_dout  = 16'h0;
           if (~reg_cin) begin
          nxt_state = S2;
                  nxt_max   = (reg_din > reg_max) ? 
                   reg_din : reg_max;
           end
        end
      S2: 
        begin // wait for SYNC1
           fsm_cout  = 1'b0;
               fsm_dout  = 16'h0;
           if (reg_cin) begin
          nxt_state = S3;
           end
            end
          S3:  
        begin // wait for SYNC0
           fsm_cout  = 1'b1;
           fsm_dout  = reg_max;
               if (~reg_cin) begin
          nxt_state = S0;
           end
            end
    endcase   
     end
      
endmodule

