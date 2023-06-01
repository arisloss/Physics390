-- Top-level design for ipbus demo on the VC709
-- Kristian Hahn & Marco Trovato
-- Northwestern University, 16/4/14

-- Modified by Charlie Strohman crs5@cornell.edu Oct 13, 2014
-- 1) Replace the Xilinx ethernet MAC (which needs a purchased license) with
--    a MAC from Mr. Wu of BU.
-- 2) Converted to Vivado, which required creating new pinout and timing
--    constraint files
-- 3) Update the ethernet PHY to version 14.1
-- 4) Changed the MAC and IP addresses farther down in this file to those
--    suitable for my board and subnet.
-- 5) Started using the 200 MHz clock for new PHY

-- Verified on a Rev 1.0 vc709.

-- Clocking for the vc709: The board does not host a fixed 125MHz oscillator.
-- GTH Bank 113 for the SFPs accepts clock from either the jitter attenuator
-- or from the MGT SMA inputs.  For the example, we chose to divide the
-- 156.25MHz default clock from the on-board progammable oscillator to 125MHz.
-- This is routed over the user SMA connectors to the MGT SMA connectors via
-- cable loopback, similar to the setup described in the XTP234 VC709 IBERT
-- guide. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

use work.ipbus.ALL;
use work.ipbus_reg_types.all;
use work.ipbus_address_decode.all;

entity top is
  port(
    -- clocking & GT
    sma_clk_n, sma_clk_p: out std_logic;
    clk200_n, clk200_p: in std_logic;        
    prog_clk_n, prog_clk_p: in std_logic;        
    gt_clkp, gt_clkn: in std_logic;
    gt_txp, gt_txn: out std_logic;
    gt_rxp, gt_rxn: in std_logic;
    -- SFP
    sfp_los, sfp_mod_det: in std_logic;   
    sfp_rs0, sfp_rs1: out std_logic;        
    sfp_tx_disable: out std_logic;  
    -- LEDs
    leds: out std_logic_vector(7 downto 0)
  );

end top;

architecture rtl of top is

  -- ipbus
  signal clkdiv_clk, clkdiv_locked, clkdiv_rst, clkdiv_fb : std_logic;
  signal clk_156_25, clk125_ub, clk125_bufg, clk125_clean : std_logic;
  signal clk125_fr, clk125, clk100, clk200, ipb_clk, clk_locked, locked, eth_locked: std_logic;
  signal rst_125, rst_ipb, rst_eth, onehz: std_logic;
  signal mac_tx_data, mac_rx_data: std_logic_vector(7 downto 0);
  signal mac_tx_valid, mac_tx_last, mac_tx_error, mac_tx_ready: std_logic;
  signal mac_rx_valid, mac_rx_last, mac_rx_error: std_logic;
  signal ipb_master_out : ipb_wbus;
  signal ipb_master_in : ipb_rbus;
  signal mac_addr: std_logic_vector(47 downto 0);
  signal ip_addr: std_logic_vector(31 downto 0);
  signal pkt_rx, pkt_tx, pkt_rx_led, pkt_tx_led, sys_rst: std_logic;	
  signal light_detect: std_logic;
  signal link_status: std_logic; 
  signal eth_phy_status_vector: std_logic_vector(15 downto 0);
  signal gtrefclk_out, eth_link_status: std_logic;  

  signal ipb_w_array  : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipb_r_array  : ipb_rbus_array(N_SLAVES - 1 downto 0);

  signal ctrl_reg_p, stat_reg_p : ipb_reg_v(9 downto 0);
  
  
  
  -- prng
  signal rand_reset, rand_valid, rand_reseed, rand_request : std_logic;
  signal rand_seed, rand_value : std_logic_vector(31 downto 0);  

  -- integral
  signal integral_start, integral_done, integral_ready, integral_reset, integral_idle : std_logic;
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

  signal integral_counter : std_logic_vector(31 downto 0) := (others => '0');
  signal integral_timing_counter : std_logic_vector(63 downto 0) := (others => '0');  
  signal ipb_ram_address  : std_logic_vector(5 downto 0) := (others => '0');  
  
begin

  -- value initialization
  sfp_rs0 <= '0';                       -- for AFBR-703SDDZ, sets 1.25 Gbps
  sfp_rs1 <= '0';                       --
  sfp_tx_disable <= '0';
  light_detect <= not sfp_los;
  locked <= clk_locked and eth_locked;
  leds <= (pkt_rx_led, pkt_tx_led, clkdiv_locked, clk_locked, eth_locked, onehz, light_detect, not sfp_mod_det);
  mac_addr <= X"000a3502ddcc";          -- from the sticker on the board ...
  ip_addr <= X"c0a82032";               -- 192.168.32.50

  
  --	DCM clock generation for internal bus, ethernet
  clocks: entity work.clocks_7s_serdes
    port map(
      clki_fr => clk125_fr,
      clki_125 => clk125,
      clko_ipb => ipb_clk,
      eth_locked => eth_locked,
      locked => clk_locked,
      nuke => sys_rst,
      rsto_125 => rst_125,
      rsto_ipb => rst_ipb,
      rsto_eth => rst_eth,
      onehz => onehz
      );
  
  -- Ethernet MAC core and PHY interface
  eth: entity work.eth_7s_1000basex
    generic map ( AN_enable => 1 )
    port map(
      gt_clkp => gt_clkp,
      gt_clkn => gt_clkn,
      gt_txp => gt_txp,
      gt_txn => gt_txn,
      gt_rxp => gt_rxp,
      gt_rxn => gt_rxn,
      sig_detn => sfp_los,
      locked => eth_locked,
      tx_data => mac_tx_data,
      tx_valid => mac_tx_valid,
      tx_last => mac_tx_last,
      tx_error => mac_tx_error,
      tx_ready => mac_tx_ready,
      rx_data => mac_rx_data,
      rx_valid => mac_rx_valid,
      rx_last => mac_rx_last,
      rx_error => mac_rx_error,
      clk125_out => clk125,
      clk125_out_fr => clk125_fr,
      rsti => rst_eth,
      clk200 => clk200
      );
 
  -- ipbus control logic
  ipbus: entity work.ipbus_ctrl
    port map(
      mac_clk => clk125,
      rst_macclk => rst_125,
      ipb_clk => ipb_clk,
      rst_ipb => rst_ipb,
      mac_rx_data => mac_rx_data,
      mac_rx_valid => mac_rx_valid,
      mac_rx_last => mac_rx_last,
      mac_rx_error => mac_rx_error,
      mac_tx_data => mac_tx_data,
      mac_tx_valid => mac_tx_valid,
      mac_tx_last => mac_tx_last,
      mac_tx_error => mac_tx_error,
      mac_tx_ready => mac_tx_ready,
      ipb_out => ipb_master_out,
      ipb_in => ipb_master_in,
      mac_addr => mac_addr,
      ip_addr => ip_addr,
      pkt_rx => pkt_rx,
      pkt_tx => pkt_tx,
      pkt_rx_led => pkt_rx_led,
      pkt_tx_led => pkt_tx_led
      );




  -------------------------------------------------------------------------------------
  -- Buffer incoming clocks
  -- the SYSCLK oscillator outputs 200.0 Mhz 
  IBUFGDS_clk200 : IBUFGDS
  port map (I  => clk200_p, IB => clk200_n, O  => clk200);

  -- the programmable oscillator outputs 156.25 Mhz 
  IBUFGDS_prog : IBUFGDS
  port map (I  => prog_clk_p, IB => prog_clk_n, O  => clk_156_25);

  -- divide the 'prog_clk' down to 125 MHz
  -- This should be replaced someday by configuring the programmable clock directly 
  mcmm: MMCME2_BASE
    generic map(
      BANDWIDTH => "HIGH",
      CLKIN1_PERIOD => 6.400,
      CLKFBOUT_MULT_F => 46.000,
      DIVCLK_DIVIDE => 5,
      CLKOUT0_DIVIDE_F => 11.5
      )
    port map(
      clkin1 => clk_156_25,
      clkout0 => clk125_ub,
      clkfbout => clkdiv_fb,
      clkfbin => clkdiv_fb,
      rst => clkdiv_rst,
      pwrdwn => '0',
      locked => clkdiv_locked);
  clkdiv_rst <= sys_rst;

  -- buffer the divided clock 
  BUFG_inst : BUFG
    port map (I => clk125_ub, O => clk125_bufg);

  -- clean it up with a DDR flip flop
  ODDR_inst : ODDR
    port map (    Q =>  clk125_clean,  -- 1-bit DDR output,
                  C =>  clk125_bufg,   -- 1-bit clock input 
                  CE => '1',
                  D1 => '1',  -- 1-bit data input (positive edge)
                  D2 => '0'   -- 1-bit data input (negative edge),
                  );                  

  -- loop it over the SMA connectors to the MGT
  OBUFDS_inst : OBUFDS
    generic map (
      IOSTANDARD => "LVDS"
      )
    port map (I => clk125_clean, O =>  sma_clk_p, OB => sma_clk_n);


  -------------------------------------------------------------------------------------
  -- IPBus stuff
  --

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_master_out,
      ipb_out         => ipb_master_in,
      sel             => ipbus_sel_address(ipb_master_out.ipb_addr),
      ipb_to_slaves   => ipb_w_array,
      ipb_from_slaves => ipb_r_array
      );


  csr : entity work.ipbus_syncreg_v
    generic map(
      N_CTRL => 10,
      N_STAT => 10
      )
    port map(
      clk        => ipb_clk,
      rst        => rst_ipb,    
      ipb_in     => ipb_w_array(N_SLV_CSR),
      ipb_out    => ipb_r_array(N_SLV_CSR),
      slv_clk    => clk200,
      d          => stat_reg_p,
      q          => ctrl_reg_p
      );  
  rand_request                    <= ctrl_reg_p(0)(0);        
  rand_reset                      <= ctrl_reg_p(0)(1);
  integral_start                  <= ctrl_reg_p(0)(2);        
  integral_reset                  <= ctrl_reg_p(0)(3);
  integral_params_0(31 downto 0)  <= ctrl_reg_p(1);
  integral_params_0(63 downto 32) <= ctrl_reg_p(2);
  integral_params_1(31 downto 0)  <= ctrl_reg_p(3);
  integral_params_1(63 downto 32) <= ctrl_reg_p(4);    
  integral_range_i(31 downto 0)  <= ctrl_reg_p(5)(31 downto 0);      
  integral_range_i(63 downto 32) <= ctrl_reg_p(6)(31 downto 0);
  integral_range_f(31 downto 0)  <= ctrl_reg_p(7)(31 downto 0);      
  integral_range_f(63 downto 32) <= ctrl_reg_p(8)(31 downto 0);
  integral_ntrials(31 downto 0)  <= ctrl_reg_p(9)(31 downto 0);
  integral_ntrials(63 downto 32) <= (others => '0');

  stat_reg_p(0)(0)   <= integral_idle;
  stat_reg_p(0)(1)   <= integral_ready;
  stat_reg_p(0)(2)   <= integral_done;
  stat_reg_p(1)      <= x"BABEFACE";
  stat_reg_p(2)      <= results.integral(31 downto 0);
  stat_reg_p(3)      <= results.integral(63 downto 32);
  stat_reg_p(4)      <= results.err(31 downto 0);
  stat_reg_p(5)      <= results.err(63 downto 32);
  stat_reg_p(6)      <= integral_counter;  
  

  --
  -- output rams
  --
  ram_integral : entity work.ipbus_ported_dpram72
    generic map(ADDR_WIDTH => 6)
    port map(
      clk        => ipb_clk,
      rst        => rst_ipb,
      ipb_in     => ipb_w_array(N_SLV_RAM_INTEGRAL),
      ipb_out    => ipb_r_array(N_SLV_RAM_INTEGRAL),
      rclk       => clk200,
      we         => integral_done and integral_start,
      d(63 downto 0)          => results.integral,
      d(71 downto 64)         => (others => '0'),
      q          =>  open,
      addr       => ipb_ram_address
      );

  ram_error : entity work.ipbus_ported_dpram72
    generic map(ADDR_WIDTH => 6)
    port map(
      clk        => ipb_clk,
      rst        => rst_ipb,
      ipb_in     => ipb_w_array(N_SLV_RAM_ERROR),
      ipb_out    => ipb_r_array(N_SLV_RAM_ERROR),
      rclk       => clk200,
      we         => integral_done and integral_start,
      d(63 downto 0)          => results.err,
      d(71 downto 64)         => (others => '0'),
      q          =>  open,
      addr       => ipb_ram_address
      );

  ram_timing : entity work.ipbus_ported_dpram72
    generic map(ADDR_WIDTH => 6)
    port map(
      clk        => ipb_clk,
      rst        => rst_ipb,
      ipb_in     => ipb_w_array(N_SLV_RAM_TIMING),
      ipb_out    => ipb_r_array(N_SLV_RAM_TIMING),
      rclk       => clk200,
      we         => integral_done and integral_start,
      d(63 downto 0)          => integral_timing_counter,
      d(71 downto 64)         => (others => '0'),
      q          =>  open,
      addr       => ipb_ram_address
      );    


  -------------------------------------------------------------------------------------
  -- integration
  --

  myrand : entity work.rng_mt19937
    generic map( init_seed => X"DEADBEEF",
                 force_const_mul => false )
    port map(
      clk => clk200,
      rst => rand_reset,
      reseed => rand_reseed,
      newseed => rand_seed,
      out_ready => rand_request,
      out_valid => rand_valid,
      out_data  => rand_value
  );


  integral : entity work.integrate_1D_MeanVariance_Gaussian_1
    port map (
      ap_clk        => clk200,
      ap_rst        => integral_reset,
      ap_start      => integral_start,
      ap_done       => integral_done,
      ap_idle       => integral_idle,
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
    

  timing : process( clk200 )
  begin
    if( rising_edge(clk200) ) then

      -- time the integral 
      if( integral_reset = '1' or integral_ready = '1' ) then
        integral_timing_counter <= (others => '0');
      else
        integral_timing_counter <= integral_timing_counter + "1";
      end if;

      -- increment RAM address
      if ( integral_done = '1' ) then
        ipb_ram_address <= ipb_ram_address + "1";
      end if;

    end if;    
  end process;

  -------------------------------------------------------------------------------------
  -- ILA
  --

  myila : entity work.ila_0
    port map(
      clk        => clk200,
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
      probe9(0)  => integral_idle,
      probe10(0) => integral_done,
      probe11    => integral_params_0,--64b
      probe12    => integral_params_1,--64b                        
      probe13    => integral_range_i,--64b
      probe14    => integral_range_f,--64b
      probe15    => integral_ntrials,--64b
      probe16    => results.integral,--64b
      probe17    => results.variance,--64b
      probe18    => results.err,--64b                                          
      --
      probe19    => integral_timing_counter, --64b
      probe20    => integral_counter, --32b
      probe21    => ipb_ram_address --6b

      );  

  
end rtl;

