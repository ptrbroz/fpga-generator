library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity uart_rx is
generic (
DATA_BITS : integer := 8;
UART_BAUD_RATE : integer := 230400;
TARGET_MCLK : integer := 50000000);
port (
     clock : in std_logic; 
     --reset : in std_logic; 
      data : out std_logic_vector(DATA_BITS-1 downto 0); 
      send : out std_logic; 
      fe   : out std_logic; 
      rxd  : in std_logic; 
		data_out : out std_logic;
		data_out_clk : out std_logic);
end uart_rx;
 
architecture rtl of uart_rx is
    type rx_states_t is (rx_ready, rx_start_bit, rx_receiv, rx_stop_bit); 
signal rx_state : rx_states_t;
signal rx_br_cntr : integer range 0 to TARGET_MCLK/UART_BAUD_RATE-1;
signal rx_bit_cntr : integer range 0 to DATA_BITS;
signal rx_data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
signal rxd_latch : std_logic := '1';
 
 
 
begin
 
 data <= rx_data;
 
prijem : process (clock) is --, reset) is
  variable startCounterOk : integer range 0 to TARGET_MCLK/UART_BAUD_RATE := 0;
  variable startCounterFail : integer range 0 to TARGET_MCLK/UART_BAUD_RATE := 0;
  begin
       if rising_edge(clock) then
             rxd_latch <= rxd;
             case rx_state is
                 when rx_ready =>
                      send <= '0';
                      fe <= '0';
                      if rxd_latch = '0' then
                                rx_bit_cntr <= DATA_BITS;
                                rx_state <= rx_start_bit;
                                rx_br_cntr <= (TARGET_MCLK/UART_BAUD_RATE-1)/2;
										  startCounterOk := 0;
										  startCounterFail := 0;
                      end if;
                 when rx_start_bit => 
                       if rx_br_cntr = 0 then
								  if startCounterOk > startCounterFail then
										rx_state <= rx_receiv;
										rx_br_cntr <= TARGET_MCLK/UART_BAUD_RATE-1;
								  else
										rx_state <= rx_ready;
								  end if;
                       else
                          rx_br_cntr <= rx_br_cntr - 1;
								  if rxd_latch = '0' then
								      startCounterOk := startCounterOk + 1;
								  else
								      startCounterFail := startCounterFail + 1;
								  end if;
                       end if;
                  when rx_receiv =>
                        if rx_br_cntr = 0 then
                           if rx_bit_cntr /= 0 then
                                 rx_data(DATA_BITS - rx_bit_cntr) <= rxd_latch;
											data_out <= rxd_latch;
											data_out_clk <= '1';
                                 rx_br_cntr <= TARGET_MCLK/UART_BAUD_RATE-1;
											if rx_bit_cntr = 1 then
												rx_state <= rx_stop_bit;
											end if;
                                 rx_bit_cntr <= rx_bit_cntr - 1;
                           else
                                 rx_state <= rx_stop_bit;
                                 rx_br_cntr <= TARGET_MCLK/UART_BAUD_RATE-1;
                           end if;
                       else
                         rx_br_cntr <= rx_br_cntr - 1;
								 data_out_clk <= '0';
                       end if; 
                   when rx_stop_bit =>
                        if rx_br_cntr = 0 then
                            rx_state <= rx_ready;
									 --data <= rx_data;
                              fe <= '1';
										send <= '1';
                         else
                           rx_br_cntr <= rx_br_cntr - 1; 
                         end if;
              end case;
      end if;
end process prijem;
 
end rtl;