--
-- File            :   nf_hz_stall_unit.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is stall and flush hazard unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;

entity nf_hz_stall_unit is
    port
    (
        -- scan wires
        we_rf_imem  : in   std_logic;                       -- write enable register from memory stage
        wa3_iexe    : in   std_logic_vector(4 downto 0);    -- write address from execution stage
        wa3_imem    : in   std_logic_vector(4 downto 0);    -- write address from execution stage
        we_rf_iexe  : in   std_logic;                       -- write enable register from memory stage
        rf_src_iexe : in   std_logic;                       -- register source from execution stage
        ra1_id      : in   std_logic_vector(4 downto 0);    -- read address 1 from decode stage
        ra2_id      : in   std_logic_vector(4 downto 0);    -- read address 2 from decode stage
        branch_type : in   std_logic_vector(3 downto 0);    -- branch type
        we_dm_imem  : in   std_logic;                       -- write enable data memory from memory stage
        req_ack_dm  : in   std_logic;                       -- request acknowledge data memory
        req_ack_i   : in   std_logic;                       -- request acknowledge instruction
        rf_src_imem : in   std_logic;                       -- register source from memory stage
        lsu_busy    : in   std_logic;                       -- load store unit busy
        lsu_err     : in   std_logic;                       -- load store error
        -- control wires
        stall_if    : out  std_logic;                       -- stall fetch stage
        stall_id    : out  std_logic;                       -- stall decode stage
        stall_iexe  : out  std_logic;                       -- stall execution stage
        stall_imem  : out  std_logic;                       -- stall memory stage
        stall_iwb   : out  std_logic;                       -- stall write back stage
        flush_id    : out  std_logic;                       -- flsuh decode stage
        flush_iexe  : out  std_logic;                       -- flush execution stage
        flush_imem  : out  std_logic;                       -- flush memory stage
        flush_iwb   : out  std_logic                        -- flush write back stage
    );
end nf_hz_stall_unit;

architecture rtl of nf_hz_stall_unit is
    signal lw_stall_id_iexe     : std_logic;    -- stall pipe if load data instructions ( id and exe stages )
    signal branch_exe_id_stall  : std_logic;    -- stall pipe if branch operations
    signal sw_lw_data_stall     : std_logic;    -- stall pipe if store or load data instructions
    signal lw_instr_stall       : std_logic;    -- stall pipe if load instruction from memory
begin

    lw_stall_id_iexe    <=  ( bool2sl( ra1_id = wa3_iexe ) or bool2sl( ra2_id = wa3_iexe ) or bool2sl( ra1_id = wa3_imem ) or bool2sl( ra2_id = wa3_imem ) ) and 
                            ( we_rf_iexe  or we_rf_imem  ) and 
                            ( rf_src_iexe or rf_src_imem );

    branch_exe_id_stall <=  ( not ( bool2sl( branch_type = B_NONE ) ) ) and 
                            we_rf_iexe and 
                            ( bool2sl( wa3_iexe = ra1_id ) or bool2sl( wa3_iexe = ra2_id ) ) and 
                            ( bool2sl( ra1_id /= 5X"00"  ) or bool2sl( ra2_id /= 5X"00"  ) );

    sw_lw_data_stall    <=   lsu_busy;

    lw_instr_stall      <=   not req_ack_i;
    -- stall wires
    stall_if   <= lw_stall_id_iexe  or sw_lw_data_stall or branch_exe_id_stall or lw_instr_stall;
    stall_id   <= lw_stall_id_iexe  or sw_lw_data_stall or branch_exe_id_stall or lw_instr_stall;
    stall_iexe <=                      sw_lw_data_stall;
    stall_imem <=                      sw_lw_data_stall;
    stall_iwb  <=                      sw_lw_data_stall;
    -- flush wires
    flush_iexe <= lsu_err or lw_stall_id_iexe  or branch_exe_id_stall or lw_instr_stall;
    flush_id   <= lsu_err                                                              ;
    flush_imem <= lsu_err                                                              ;
    flush_iwb  <= lsu_err                                                              ;

end rtl; -- nf_hz_stall_unit
