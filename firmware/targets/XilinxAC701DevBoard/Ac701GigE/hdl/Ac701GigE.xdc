##############################################################################
## This file is part of 'Example Project Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'Example Project Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
# I/O Port Mapping
set_property PACKAGE_PIN U4 [get_ports extRst]
set_property IOSTANDARD LVCMOS25 [get_ports extRst]

set_property PACKAGE_PIN A24 [get_ports {clkSelA[0]}]
set_property PACKAGE_PIN C26 [get_ports {clkSelA[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports clkSelA*]

set_property PACKAGE_PIN B26 [get_ports {clkSelB[0]}]
set_property PACKAGE_PIN C24 [get_ports {clkSelB[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports clkSelB*]

set_property PACKAGE_PIN M26 [get_ports {led[0]}]
set_property PACKAGE_PIN T24 [get_ports {led[1]}]
set_property PACKAGE_PIN T25 [get_ports {led[2]}]
set_property PACKAGE_PIN R26 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports led*]

set_property PACKAGE_PIN AD12 [get_ports gtRxN]
set_property PACKAGE_PIN AC12 [get_ports gtRxP]
set_property PACKAGE_PIN AD10 [get_ports gtTxN]
set_property PACKAGE_PIN AC10 [get_ports gtTxP]

set_property PACKAGE_PIN AA13 [get_ports gtClkP]
set_property PACKAGE_PIN AB13 [get_ports gtClkN]

# XADC ports
set_property PACKAGE_PIN N12 [get_ports vPIn] set_property PACKAGE_PIN P11 [get_ports vNIn]

# Timing Constraints
create_clock -period 8.000 -name gtClkP [get_ports gtClkP]
create_generated_clock -name ethClk125MHz [get_pins U_ETH_PHY_MAC/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0]
create_generated_clock -name ethClk62p5MHz [get_pins U_ETH_PHY_MAC/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1]
create_generated_clock -name dnaClk [get_pins U_App/U_Reg/U_AxiVersion/GEN_DEVICE_DNA.DeviceDna_1/GEN_7SERIES.DeviceDna7Series_Inst/BUFR_Inst/O]

set_clock_groups -asynchronous -group [get_clocks ethClk125MHz] -group [get_clocks dnaClk]

# StdLib
set_property ASYNC_REG true [get_cells -hierarchical *crossDomainSyncReg_reg*]

# .bit File Configuration
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

connect_debug_port u_ila_0/probe0 [get_nets [list {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][0]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][1]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][2]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][3]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][4]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][5]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][6]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/v[macMaster][tData][7]}]]
connect_debug_port u_ila_0/probe1 [get_nets [list {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[0]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[1]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[2]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[3]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[4]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[5]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[6]} {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/FFData[7]}]]
connect_debug_port u_ila_0/probe2 [get_nets [list {U_ETH_PHY_MAC/GEN_LANE[0].U_GigEthGtp7/U_MAC/U_EthMac/U_1G_IMPORT.U_EthMacImport/macSlave[tReady]}]]

