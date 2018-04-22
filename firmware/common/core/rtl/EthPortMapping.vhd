-------------------------------------------------------------------------------
-- File       : EthPortMapping.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-30
-- Last update: 2017-03-17
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'Example Project Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'Example Project Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.EthMacPkg.all;

entity EthPortMapping is
   generic (
      TPD_G           : time             := 1 ns;
      CLK_FREQUENCY_G : real             := 125.0E+6;
      MAC_ADDR_G      : slv(47 downto 0) := x"010300564400";  -- 00:44:56:00:03:01 (ETH only)
      IP_ADDR_G       : slv(31 downto 0) := x"0A02A8C0";  -- 192.168.2.10 (ETH only)
      DHCP_G          : boolean          := true;
      JUMBO_G         : boolean          := false;
      RSSI_SIZE_G     : natural          := 0;
      RSSI_STRM_CFG_G : AxiStreamConfigArray;
      RSSI_ROUTES_G   : Slv8Array;
      UDP_SRV_SIZE_G  : natural          := 0;
      UDP_SRV_PORTS_G : PositiveArray
   );
   port (
      -- Clock and Reset
      clk             : in  sl;
      rst             : in  sl;
      -- ETH interface
      txMaster        : out AxiStreamMasterType;
      txSlave         : in  AxiStreamSlaveType;
      rxMaster        : in  AxiStreamMasterType;
      rxSlave         : out AxiStreamSlaveType;
      rxCtrl          : out AxiStreamCtrlType;
      -- RSSI Streams
      rssiIbMasters   : in  AxiStreamMasterArray(RSSI_SIZE_G - 1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      rssiIbSlaves    : out AxiStreamSlaveArray (RSSI_SIZE_G - 1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      rssiObMasters   : out AxiStreamMasterArray(RSSI_SIZE_G - 1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      rssiObSlaves    : in  AxiStreamSlaveArray (RSSI_SIZE_G - 1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      -- UDP Streams
      udpIbMasters    : in  AxiStreamMasterArray(UDP_SRV_SIZE_G - 1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      udpIbSlaves     : out AxiStreamSlaveArray (UDP_SRV_SIZE_G - 1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      udpObMasters    : out AxiStreamMasterArray(UDP_SRV_SIZE_G - 1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      udpObSlaves     : in  AxiStreamSlaveArray (UDP_SRV_SIZE_G - 1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      -- AXI-Lite Interface
      axilWriteMaster : out AxiLiteWriteMasterType;
      axilWriteSlave  : in  AxiLiteWriteSlaveType;
      axilReadMaster  : out AxiLiteReadMasterType;
      axilReadSlave   : in  AxiLiteReadSlaveType);
end EthPortMapping;

architecture mapping of EthPortMapping is

   -- assume descending arrays with right index 0
   function cat(a,b : PositiveArray) return PositiveArray is
      variable c : PositiveArray(a'length+b'length-1 downto 0);
   begin
      c(a'range)                := a;
      c(c'left-1 downto a'left) := b;
      return c;
   end function cat;

   function cat(a,b : AxiStreamConfigArray) return AxiStreamConfigArray is
      variable c : AxiStreamConfigArray(a'length+b'length-1 downto 0);
   begin
      c(a'range)                := a;
      c(c'left-1 downto a'left) := b;
      return c;
   end function cat;

   function cat(a,b : Slv8Array) return Slv8Array is
      variable c : Slv8Array(a'length+b'length-1 downto 0);
   begin
      c(a'range)                := a;
      c(c'left-1 downto a'left) := b;
      return c;
   end function cat;


   constant JTAG_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant NUM_INT_SERVERS_C  : integer                                     := 2;
   constant INT_SERVER_PORTS_C : PositiveArray(NUM_INT_SERVERS_C-1 downto 0) := (0 => 8193, 1 => 2542);
   constant NUM_SERVERS_C      : integer                                     := NUM_INT_SERVERS_C + UDP_SRV_SIZE_G;
   constant SERVER_PORTS_C     : PositiveArray(NUM_SERVERS_C-1 downto 0)     :=
      cat(INT_SERVER_PORTS_C, UDP_SRV_PORTS_G);

   constant INT_RSSI_SIZE_C : positive := 1;
   constant RSSI_SIZE_C     : positive := RSSI_SIZE_G + INT_RSSI_SIZE_C;
   constant SRP_RSSI_CFG_C  : AxiStreamConfigArray(INT_RSSI_SIZE_C - 1 downto 0) := (
      0 => ssiAxiStreamConfig(4)
   );
   constant AXIS_CONFIG_C : AxiStreamConfigArray(RSSI_SIZE_C-1 downto 0) :=
      cat( SRP_RSSI_CFG_C, RSSI_STRM_CFG_G );

   constant INT_RSSI_ROUTES_C : Slv8Array(INT_RSSI_SIZE_C - 1 downto 0) := (
      0 => x"00"
   );
   constant RSSI_ROUTES_C : Slv8Array(RSSI_SIZE_C-1 downto 0) :=
      cat( INT_RSSI_ROUTES_C, RSSI_ROUTES_G );

   signal ibServerMasters : AxiStreamMasterArray(NUM_SERVERS_C-1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(NUM_SERVERS_C-1 downto 0);
   signal obServerMasters : AxiStreamMasterArray(NUM_SERVERS_C-1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(NUM_SERVERS_C-1 downto 0);

   signal rssiIbMastersLoc: AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal rssiIbSlavesLoc : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);
   signal rssiObMastersLoc: AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal rssiObSlavesLoc : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);

   signal spliceSOF       : AxiStreamMasterType;

   constant USE_JTAG_C    : boolean := true;
   
begin

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UDP : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G          => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => NUM_SERVERS_C,
         SERVER_PORTS_G => SERVER_PORTS_C,
         -- UDP Client Generics
         CLIENT_EN_G    => false,
         -- General IPv4/ARP/DHCP Generics
         DHCP_G         => DHCP_G,
         CLK_FREQ_G     => CLK_FREQUENCY_G,
         COMM_TIMEOUT_G => 30)
      port map (
         -- Local Configurations
         localMac        => MAC_ADDR_G,
         localIp         => IP_ADDR_G,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster     => rxMaster,
         obMacSlave      => rxSlave,
         ibMacMaster     => txMaster,
         ibMacSlave      => txSlave,
         -- Interface to UDP Server engine(s)
         obServerMasters => obServerMasters,
         obServerSlaves  => obServerSlaves,
         ibServerMasters => ibServerMasters,
         ibServerSlaves  => ibServerSlaves,
         -- Clock and Reset
         clk             => clk,
         rst             => rst);

   ------------------------------------------
   -- Software's RSSI Server Interface @ 8193
   ------------------------------------------
   U_RssiServer : entity work.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         MAX_SEG_SIZE_G      => 1024,
         SEGMENT_ADDR_SIZE_G => 7,
         APP_STREAMS_G       => RSSI_SIZE_C,
         APP_STREAM_ROUTES_G => RSSI_ROUTES_C,
         CLK_FREQUENCY_G     => CLK_FREQUENCY_G,
         TIMEOUT_UNIT_G      => 1.0E-3,  -- In units of seconds
         SERVER_G            => true,
         RETRANSMIT_ENABLE_G => true,
         BYPASS_CHUNKER_G    => false,
         WINDOW_ADDR_SIZE_G  => 3,
         PIPE_STAGES_G       => 1,
         APP_AXIS_CONFIG_G   => AXIS_CONFIG_C,
         TSP_AXIS_CONFIG_G   => EMAC_AXIS_CONFIG_C,
         INIT_SEQ_N_G        => 16#80#)
      port map (
         clk_i             => clk,
         rst_i             => rst,
         openRq_i          => '1',
         -- Application Layer Interface
         sAppAxisMasters_i => rssiIbMastersLoc,
         sAppAxisSlaves_o  => rssiIbSlavesLoc,
         mAppAxisMasters_o => rssiObMastersLoc,
         mAppAxisSlaves_i  => rssiObSlavesLoc,
         -- Transport Layer Interface
         sTspAxisMaster_i  => obServerMasters(0),
         sTspAxisSlave_o   => obServerSlaves(0),
         mTspAxisMaster_o  => ibServerMasters(0),
         mTspAxisSlave_i   => ibServerSlaves(0));

   ---------------------------------------
   -- TDEST = 0x0: Register access control
   ---------------------------------------
   U_SRPv3 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => AXIS_CONFIG_C(0))
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain)
         sAxisClk         => clk,
         sAxisRst         => rst,
         sAxisMaster      => rssiObMastersLoc(0),
         sAxisSlave       => rssiObSlavesLoc(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => clk,
         mAxisRst         => rst,
         mAxisMaster      => rssiIbMastersLoc(0),
         mAxisSlave       => rssiIbSlavesLoc(0),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => clk,
         axilRst          => rst,
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave);

   GEN_MAP_1 : for i in RSSI_SIZE_G - 1 downto 0 generate
      rssiIbMastersLoc(i + INT_RSSI_SIZE_C) <= rssiIbMasters(i);
      rssiIbSlaves(i)                       <= rssiIbSlavesLoc (i + INT_RSSI_SIZE_C);
      rssiObMasters(i)                      <= rssiObMastersLoc(i + INT_RSSI_SIZE_C);
      rssiObSlavesLoc(i + INT_RSSI_SIZE_C)  <= rssiObSlaves(i);
   end generate;

   GEN_MAP_2 : for i in UDP_SRV_SIZE_G - 1 downto 0 generate
      obServerMasters(i + NUM_INT_SERVERS_C) <= udpIbMasters(i);
      udpIbSlaves(i)                         <= obServerSlaves  (i + NUM_INT_SERVERS_C);
      udpObMasters(i)                        <= ibServerMasters (i + NUM_INT_SERVERS_C);
      ibServerSlaves(i + NUM_INT_SERVERS_C)  <= udpObSlaves(i);
   end generate;


   P_SPLICE : process(spliceSOF)
      variable v : AxiStreamMasterType;
   begin
      v                   := spliceSOF;
      v.tUser(1 downto 0) := "10";
      ibServerMasters(1)  <= v;
   end process P_SPLICE;

   GEN_JTAG : if ( USE_JTAG_C ) generate

   U_AxisBscan : entity work.AxisJtagDebugBridge(AxisJtagDebugBridgeImpl)
      generic map (
         TPD_G        => TPD_G,
         AXIS_WIDTH_G => EMAC_AXIS_CONFIG_C.TDATA_BYTES_C,
         AXIS_FREQ_G  => CLK_FREQUENCY_G,
         CLK_DIV2_G   => 5,
         MEM_DEPTH_G  => (2048/EMAC_AXIS_CONFIG_C.TDATA_BYTES_C)
      )
      port map (
         axisClk      => clk,
         axisRst      => rst,

         mAxisReq     => obServerMasters(1),
         sAxisReq     => obServerSlaves(1),

         mAxisTdo     => spliceSOF,
         sAxisTdo     => ibServerSlaves(1)
      );

   end generate;

   GEN_JTAG_STUB : if ( not USE_JTAG_C ) generate

   U_AxisBscan : entity work.AxisJtagDebugBridge(AxisJtagDebugBridgeStub)
      generic map (
         TPD_G        => TPD_G,
         AXIS_WIDTH_G => EMAC_AXIS_CONFIG_C.TDATA_BYTES_C,
         AXIS_FREQ_G  => CLK_FREQUENCY_G,
         CLK_DIV2_G   => 5,
         MEM_DEPTH_G  => (2048/EMAC_AXIS_CONFIG_C.TDATA_BYTES_C)
      )
      port map (
         axisClk      => clk,
         axisRst      => rst,

         mAxisReq     => obServerMasters(1),
         sAxisReq     => obServerSlaves(1),

         mAxisTdo     => spliceSOF,
         sAxisTdo     => ibServerSlaves(1)
      );

   end generate;


end mapping;
