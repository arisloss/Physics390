library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
  Port (
    -- system clock
    sysclk_p : in STD_LOGIC;
    sysclk_n : in STD_LOGIC;
    -- LEDs 
    gpio_led_7_ls : out std_logic;
    gpio_led_6_ls : out std_logic;
    gpio_led_5_ls : out std_logic;      
    gpio_led_4_ls : out std_logic;
    gpio_led_3_ls : out std_logic;
    gpio_led_2_ls : out std_logic;
    gpio_led_1_ls : out std_logic;
    gpio_led_0_ls : out std_logic;
    -- DIP switch
    gpio_dip_sw1  : in std_logic
    );
end top;

architecture Behavioral of top is

  signal sysclk : STD_LOGIC;
  signal rand_reset, rand_valid, rand_reseed, rand_request : std_logic;
  signal rand_seed, rand_value : std_logic_vector(31 downto 0);  
  
begin

  sysbuf : entity IBUFDS
  port map(
    I  => sysclk_p,
    IB => sysclk_n,
    O  => sysclk
    );

  myrand : entity work.rng_mt19937
    generic map( init_seed => X"DEADBEEF",
                 force_const_mul => false )
    port map(
      clk => sysclk,
      rst => rand_reset,
      reseed => rand_reseed,
      newseed => rand_seed,
      out_ready => rand_request,
      out_valid => rand_valid,
      out_data  => rand_value
  );

  myila : entity work.ila_0
    port map(
      clk        => sysclk,
      probe0(0)  => rand_reset, --1b
      probe1(0)  => rand_request, --1b
      probe2(0)  => rand_valid, --1b      
      probe3(0)  => rand_reseed, --1b
      probe4     => rand_seed, --32b      
      probe5     => rand_value --32b
      );

  myvio : entity work.vio_0 
    port map(
      clk            => sysclk,
      probe_out0(0)  => rand_reset,
      probe_out1(0)  => rand_request,
      probe_out2(0)  => rand_reseed,
      probe_out3     => rand_seed,                  
      probe_in0(0)   => rand_valid,
      probe_in1      => rand_value
      );
  

end Behavioral;
  
