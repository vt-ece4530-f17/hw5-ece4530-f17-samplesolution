
module mspconnect (
	clk_clk,
	reset_reset_n,
	rs232_0_external_interface_RXD,
	rs232_0_external_interface_TXD,
	rs232_1_external_interface_RXD,
	rs232_1_external_interface_TXD);	

	input		clk_clk;
	input		reset_reset_n;
	input		rs232_0_external_interface_RXD;
	output		rs232_0_external_interface_TXD;
	input		rs232_1_external_interface_RXD;
	output		rs232_1_external_interface_TXD;
endmodule
