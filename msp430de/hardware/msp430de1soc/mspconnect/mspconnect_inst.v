	mspconnect u0 (
		.clk_clk                        (<connected-to-clk_clk>),                        //                        clk.clk
		.reset_reset_n                  (<connected-to-reset_reset_n>),                  //                      reset.reset_n
		.rs232_0_external_interface_RXD (<connected-to-rs232_0_external_interface_RXD>), // rs232_0_external_interface.RXD
		.rs232_0_external_interface_TXD (<connected-to-rs232_0_external_interface_TXD>), //                           .TXD
		.rs232_1_external_interface_RXD (<connected-to-rs232_1_external_interface_RXD>), // rs232_1_external_interface.RXD
		.rs232_1_external_interface_TXD (<connected-to-rs232_1_external_interface_TXD>)  //                           .TXD
	);

