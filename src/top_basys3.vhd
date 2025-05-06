--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
port(
    -- inputs
  clk     :   in std_logic; -- native 100MHz FPGA clock
  sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
  btnU    :   in std_logic; -- reset
  btnC    :   in std_logic; -- fsm cycle
  
  -- outputs
  led :   out std_logic_vector(15 downto 0); -- cyc and flags
  -- 7-segment display segments (active-low cathodes)
  seg :   out std_logic_vector(6 downto 0);
  -- 7-segment display active-low enables (anodes)
  an  :   out std_logic_vector(3 downto 0)
);
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
  -- declare components and signals
  
  component controller_fsm is 
  port(
    i_reset : in  STD_LOGIC;
    i_adv   : in  STD_LOGIC;
    o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
  );
  end component controller_fsm;
  
  component ALU is 
  port( 
    i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
    i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
    i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
    o_result : out STD_LOGIC_VECTOR (7 downto 0);
    o_flags  : out STD_LOGIC_VECTOR (3 downto 0)
  );
  end component ALU;
  
  component clock_divider is
    generic(constant k_DIV : natural := 2	);
    port(
      i_clk    : in  std_logic;
      i_reset  : in  std_logic;
      o_clk    : out std_logic
    );
  end component clock_divider;
  
  component twos_comp is
  port(
    i_bin  : in  std_logic_vector(7 downto 0);
    o_sign : out std_logic;
    o_hund : out std_logic_vector(3 downto 0);
    o_tens : out std_logic_vector(3 downto 0);
    o_ones : out std_logic_vector(3 downto 0)
  );
  end component twos_comp;
    
  component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    port( 
      i_clk		: in  STD_LOGIC;
      i_reset : in  STD_LOGIC; -- asynchronous
      i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		  i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		  i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		  i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		  o_data	: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		  o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
  end component TDM4;
  
  component sevenseg_decoder is
  port(
    i_Hex   : in STD_LOGIC_VECTOR  (3 downto 0);
    o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
  end component sevenseg_decoder;

  -- signals, in
  signal w_clk  : STD_LOGIC;
  signal w_btnC : STD_LOGIC; -- advance
  signal w_btnU : STD_LOGIC; -- reset
  signal w_sw   : STD_LOGIC_VECTOR(7 downto 0);
  
  -- signals, in between
  signal w_cycle : STD_LOGIC_VECTOR(3 downto 0); -- one-hot cycle
  
  signal w_A      : STD_LOGIC_VECTOR(7 downto 0); -- ALU
  signal w_B      : STD_LOGIC_VECTOR(7 downto 0);
  signal w_op     : STD_LOGIC_VECTOR(2 downto 0);
  signal w_result : STD_LOGIC_VECTOR(7 downto 0);
  signal w_flags  : STD_LOGIC_VECTOR(3 downto 0);
  
  signal w_clk_TDM : STD_LOGIC; -- divided clk
  
  signal w_valdispbin : STD_LOGIC_VECTOR(7 downto 0); -- binary to display now

  signal w_sign : STD_LOGIC;                    -- TDM
  signal w_hund : STD_LOGIC_VECTOR(3 downto 0);
  signal w_tens : STD_LOGIC_VECTOR(3 downto 0);
  signal w_ones : STD_LOGIC_VECTOR(3 downto 0);
  signal w_sel  : STD_LOGIC_VECTOR(3 downto 0);
  
  signal w_hexofdec : STD_LOGIC_VECTOR(3 downto 0); -- 7SD
  signal w_decseg   : STD_LOGIC_VECTOR(6 downto 0);
  
  signal w_signdigitsel : STD_LOGIC_VECTOR(2 downto 0); -- for sign select mux
  signal w_seg : STD_LOGIC_VECTOR(6 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
controller_fsm_inst : controller_fsm
port map(
  i_reset => w_btnU,
  i_adv   => w_btnC,
  o_cycle => w_cycle
);

ALU_inst : ALU
port map(
  i_A      => w_A,
  i_B      => w_B,
  i_op     => w_op,
  o_result => w_result,
  o_flags  => w_flags
);

clock_divider_inst : clock_divider
port map(
  i_clk   => w_clk,
  i_reset => w_btnU,
  o_clk   => w_clk_tdm
);

twos_comp_inst : twos_comp
port map(
  i_bin  => w_valdispbin,
  o_sign => w_sign,
  o_hund => w_hund,
  o_tens => w_tens,
  o_ones => w_ones
);

TDM4_inst : TDM4
port map(
  i_clk   => w_clk_tdm,
  i_reset => w_btnU,
  i_D3    => "0000", -- don't care
  i_D2    => w_hund,
  i_D1    => w_tens,
  i_D0    => w_ones,
  o_data  => w_hexofdec,
  o_sel   => w_sel
);

sevenseg_decoder_inst : sevenseg_decoder
port map(
  i_hex   => w_hexofdec,
  o_seg_n => w_decseg
);

-- CONCURRENT STATEMENTS ----------------------------
w_op <= w_sw(2 downto 0) when w_cycle(3) = '1';
w_signdigitsel(2) <= w_sign; -- negative result?
w_signdigitsel(1) <= w_sel(3); -- anode where sign is
w_signdigitsel(0) <= w_cycle(0); -- blank cycle?

  -- cycle display multiplexer
with w_cycle select
w_valdispbin <= w_A when "0010",
                w_B when "0100",
           w_result when "1000",
         "00000000" when others; -- dont care, addressed @ anodes

  -- sign/no sign/blank/digit disp. multiplexer
with w_signdigitsel select
  w_seg <= "1111111" when "100",  -- when bit 2 = '1'
           "1111111" when "101",
           "1111111" when "110",
           "1111111" when "111",
           
           "1111111" when "000",  -- explicit match
           "0111111" when "001",
           w_decseg   when "010", "011",  -- when bits 2 downto 1 = "01"
           (others => '0') when others;   -- default

  -- signals to basys3 IO
w_clk  <= clk;
w_btnU <= btnU;
w_btnC <= btnC;
w_sw   <= sw(7 downto 0);

an(3 downto 0) <= w_sel;
seg <= w_seg;
led(3 downto 0)   <= w_cycle;
led(11 downto 4)  <= "00000000"; -- unused led -> GND
led(15 downto 12) <= w_flags;

-- process of register
register_A_proc : process(w_sw, w_cycle)
begin
  if rising_edge(w_cycle(1)) then w_A <= w_sw; end if;
end process register_A_proc;

register_B_proc : process(w_sw, w_cycle)
begin
  if rising_edge(w_cycle(2)) then w_B <= w_sw; end if;
end process register_B_proc;

end top_basys3_arch;
