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
  -- prng
  signal rand_reset, rand_valid, rand_reseed, rand_request : std_logic;
  signal rand_seed, rand_value : std_logic_vector(31 downto 0);  
  -- integral
  signal integral_start, integral_done, integral_valid, integral_ready, integral_reset: std_logic;
  signal integral_params_0, integral_params_1 : std_logic_vector(63 downto 0);
  signal integral_range_i, integral_range_f : std_logic_vector(63 downto 0);
  signal integral_ntrials : std_logic_vector(63 downto 0);    

  type IntegralResults is record
    integral : std_logic_Vector(63 downto 0);
    variance : std_logic_Vector(63 downto 0);
    err      : std_logic_Vector(63 downto 0);    
  end record;
  signal results : IntegralResults;
  signal integral_results : std_logic_vector(191 downto 0);

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


  integral : entity work.integrate_1D_MeanVariance_Gaussian_0
    port map (
      ap_clk        => sysclk,
      ap_rst        => integral_reset,
      ap_start      => integral_start,
      ap_done       => integral_done,
      ap_idle       => integral_valid,
      ap_ready      => integral_ready,
      --
      params_0      => integral_params_0, --64b
      params_1      => integral_params_1, --64b
      range_i       => integral_range_i, --64b
      range_f       => integral_range_f, --64b
      ntrials       => integral_ntrials, --64b
      prand_dout    => rand_value,
      prand_empty_n => '1', -- NB : true low
      prand_read    => open,
      --
      ap_return     => integral_results
      );
  results.integral <= integral_results(63 downto 0);
  results.variance <= integral_results(127 downto 64);
  results.err      <= integral_results(191 downto 128);  
  
  myila : entity work.ila_0
    port map(
      clk        => sysclk,
      --
      probe0(0)  => rand_reset, 
      probe1(0)  => rand_request, 
      probe2(0)  => rand_valid,       
      probe3(0)  => rand_reseed, 
      probe4     => rand_seed,  --32b      
      probe5     => rand_value, --32b
      --
      probe6(0)  => integral_reset,
      probe7(0)  => integral_start,
      probe8(0)  => integral_ready,
      probe9(0)  => integral_valid,
      probe10(0) => integral_done,
      probe11    => integral_params_0,--64b
      probe12    => integral_params_1,--64b                        
      probe13    => integral_range_i,--64b
      probe14    => integral_range_f,--64b
      probe15    => integral_ntrials,--64b
      probe16    => results.integral,--64b
      probe17    => results.variance,--64b
      probe18    => results.err--64b                                          
      );

  myvio : entity work.vio_0 
    port map(
      clk            => sysclk,
      --
      probe_out0(0)  => rand_reset,
      probe_out1(0)  => rand_request,
      probe_out2(0)  => rand_reseed,
      probe_out3     => rand_seed, --32b                 
      probe_out4(0)  => integral_reset,
      probe_out5(0)  => integral_start,
      probe_out6     => integral_params_0,--64b
      probe_out7     => integral_params_1,--64b
      probe_out8     => integral_range_i,--64b
      probe_out9     => integral_range_f,--64b
      probe_out10    => integral_ntrials,--64b                        
      --
      probe_in0(0)   => rand_valid,
      probe_in1      => rand_value, --32b
      probe_in2(0)   => integral_valid,
      probe_in3      => results.integral, --64b
      probe_in4      => results.err --64b                                                               --
      );
  

end Behavioral;
  
