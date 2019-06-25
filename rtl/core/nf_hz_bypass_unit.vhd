--
-- File            :   nf_hz_bypass_unit.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.23
-- Language        :   VHDL
-- Description     :   This is bypass hazard unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;

entity nf_hz_bypass_unit is
    port
    (
        -- scan wires
        wa3_imem    : in    std_logic_vector(4  downto 0);  -- write address from mem stage
        we_rf_imem  : in    std_logic;                      -- write enable register from mem stage
        wa3_iwb     : in    std_logic_vector(4  downto 0);  -- write address from write back stage
        we_rf_iwb   : in    std_logic;                      -- write enable register from write back stage
        ra1_id      : in    std_logic_vector(4  downto 0);  -- read address 1 from decode stage
        ra2_id      : in    std_logic_vector(4  downto 0);  -- read address 2 from decode stage
        ra1_iexe    : in    std_logic_vector(4  downto 0);  -- read address 1 from execution stage
        ra2_iexe    : in    std_logic_vector(4  downto 0);  -- read address 2 from execution stage
        -- bypass inputs
        rd1_iexe    : in    std_logic_vector(31 downto 0);  -- read data 1 from execution stage
        rd2_iexe    : in    std_logic_vector(31 downto 0);  -- read data 2 from execution stage
        result_imem : in    std_logic_vector(31 downto 0);  -- ALU result from mem stage
        wd_iwb      : in    std_logic_vector(31 downto 0);  -- write data from iwb stage
        rd1_id      : in    std_logic_vector(31 downto 0);  -- read data 1 from decode stage
        rd2_id      : in    std_logic_vector(31 downto 0);  -- read data 2 from decode stage
        -- bypass outputs
        rd1_i_exu   : out   std_logic_vector(31 downto 0);  -- bypass data 1 for execution stage
        rd2_i_exu   : out   std_logic_vector(31 downto 0);  -- bypass data 2 for execution stage
        cmp_d1      : out   std_logic_vector(31 downto 0);  -- bypass data 1 for decode stage (branch)
        cmp_d2      : out   std_logic_vector(31 downto 0)   -- bypass data 2 for decode stage (branch)
    );
end nf_hz_bypass_unit;

architecture rtl of nf_hz_bypass_unit is
    constant    HU_BP_NONE  : std_logic_vector(1 downto 0) := "00";
    constant    HU_BP_MEM   : std_logic_vector(1 downto 0) := "01";
    constant    HU_BP_WB    : std_logic_vector(1 downto 0) := "10";

    signal  rd1_bypass      : std_logic_vector(1 downto 0); -- bypass selecting for rd1 ( not branch operations )
    signal  rd2_bypass      : std_logic_vector(1 downto 0); -- bypass selecting for rd2 ( not branch operations )

    signal  cmp_d1_bypass   : std_logic;                    -- bypass selecting for rd1 ( branch operations )
    signal  cmp_d2_bypass   : std_logic;                    -- bypass selecting for rd2 ( branch operations )
begin

    cmp_d1 <= result_imem when cmp_d1_bypass else rd1_id;
    cmp_d2 <= result_imem when cmp_d2_bypass else rd2_id;

    cmp_d1_bypass <= '1' when ( bool2sl( wa3_imem = ra1_id ) and we_rf_imem and bool2sl( ra1_id /= 5X"00" ) ) else '0';    -- zero without bypass
    cmp_d2_bypass <= '1' when ( bool2sl( wa3_imem = ra2_id ) and we_rf_imem and bool2sl( ra2_id /= 5X"00" ) ) else '0';    -- zero without bypass

    bypass_comp_proc : process(all)
    begin
        rd1_bypass <= HU_BP_NONE;
        rd2_bypass <= HU_BP_NONE;
        if(    bool2sl( wa3_imem = ra1_iexe ) and we_rf_imem and bool2sl( ra1_iexe /= 5X"00" ) ) then
            rd1_bypass <= HU_BP_MEM; -- zero without bypass
        elsif( bool2sl( wa3_iwb  = ra1_iexe ) and we_rf_iwb  and bool2sl( ra1_iexe /= 5X"00" ) ) then
            rd1_bypass <= HU_BP_WB;  -- zero without bypass
        end if;
        if(    bool2sl( wa3_imem = ra2_iexe ) and we_rf_imem and bool2sl( ra2_iexe /= 5X"00" ) ) then
            rd2_bypass <= HU_BP_MEM; -- zero without bypass
        elsif( bool2sl( wa3_iwb  = ra2_iexe ) and we_rf_iwb  and bool2sl( ra2_iexe /= 5X"00" ) ) then
            rd2_bypass <= HU_BP_WB;  -- zero without bypass
        end if;
    end process;

    control_process : process(all)
    begin
        rd1_i_exu <= rd1_iexe;
        rd2_i_exu <= rd2_iexe;
        case( rd1_bypass ) is
            when HU_BP_NONE => rd1_i_exu <= rd1_iexe;
            when HU_BP_MEM  => rd1_i_exu <= result_imem;
            when HU_BP_WB   => rd1_i_exu <= wd_iwb;
            when others     => 
        end case;
        case( rd2_bypass ) is
            when HU_BP_NONE => rd2_i_exu <= rd2_iexe;
            when HU_BP_MEM  => rd2_i_exu <= result_imem;
            when HU_BP_WB   => rd2_i_exu <= wd_iwb;
            when others     => 
        end case;
    end process;

end rtl; -- nf_hz_bypass_unit
