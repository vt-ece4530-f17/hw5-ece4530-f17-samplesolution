	component mspconnect is
		port (
			clk_clk                        : in  std_logic := 'X'; -- clk
			reset_reset_n                  : in  std_logic := 'X'; -- reset_n
			rs232_0_external_interface_RXD : in  std_logic := 'X'; -- RXD
			rs232_0_external_interface_TXD : out std_logic;        -- TXD
			rs232_1_external_interface_RXD : in  std_logic := 'X'; -- RXD
			rs232_1_external_interface_TXD : out std_logic         -- TXD
		);
	end component mspconnect;

	u0 : component mspconnect
		port map (
			clk_clk                        => CONNECTED_TO_clk_clk,                        --                        clk.clk
			reset_reset_n                  => CONNECTED_TO_reset_reset_n,                  --                      reset.reset_n
			rs232_0_external_interface_RXD => CONNECTED_TO_rs232_0_external_interface_RXD, -- rs232_0_external_interface.RXD
			rs232_0_external_interface_TXD => CONNECTED_TO_rs232_0_external_interface_TXD, --                           .TXD
			rs232_1_external_interface_RXD => CONNECTED_TO_rs232_1_external_interface_RXD, -- rs232_1_external_interface.RXD
			rs232_1_external_interface_TXD => CONNECTED_TO_rs232_1_external_interface_TXD  --                           .TXD
		);

