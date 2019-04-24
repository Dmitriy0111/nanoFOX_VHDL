--
-- File            :   nf_i_du.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.23
-- Language        :   VHDL
-- Description     :   This is instruction decode unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_cpu_def.all;

entity nf_i_du is
    port 
    (
        instr       : in   std_logic_vector(31 downto 0);   -- Instruction input
        ext_data    : out  std_logic_vector(31 downto 0);   -- decoded extended data
        srcB_sel    : out  std_logic;                       -- decoded source B selection for ALU
        res_sel     : out  std_logic;                       -- for selecting result
        ALU_Code    : out  std_logic_vector(3  downto 0);   -- decoded ALU code
        shamt       : out  std_logic_vector(4  downto 0);   -- decoded for shift command's
        ra1         : out  std_logic_vector(4  downto 0);   -- decoded read address 1 for register file
        rd1         : in   std_logic_vector(31 downto 0);   -- read data 1 from register file
        ra2         : out  std_logic_vector(4  downto 0);   -- decoded read address 2 for register file
        rd2         : in   std_logic_vector(31 downto 0);   -- read data 2 from register file
        wa3         : out  std_logic_vector(4  downto 0);   -- decoded write address 2 for register file
        pc_src      : out  std_logic;                       -- decoded next program counter value enable
        we_rf       : out  std_logic;                       -- decoded write register file
        we_dm_en    : out  std_logic;                       -- decoded write data memory
        rf_src      : out  std_logic;                       -- decoded source register file signal
        size_dm     : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
        branch_src  : out  std_logic;                       -- for selecting branch source (JALR)
        branch_type : out  std_logic_vector(3  downto 0)    -- branch type
    );
end nf_i_du;

architecture rtl of nf_i_du is
    -- sign extend wires
    signal imm_data_i       : std_logic_vector(11 downto 0);    -- for I-type command's
    signal imm_data_u       : std_logic_vector(19 downto 0);    -- for U-type command's
    signal imm_data_b       : std_logic_vector(11 downto 0);    -- for B-type command's
    signal imm_data_s       : std_logic_vector(11 downto 0);    -- for S-type command's
    signal imm_data_j       : std_logic_vector(19 downto 0);    -- for J-type command's
    -- control unit wires
    signal instr_type       : std_logic_vector(1  downto 0);    -- instruction type
    signal opcode           : std_logic_vector(4  downto 0);    -- instruction operation code
    signal funct3           : std_logic_vector(2  downto 0);    -- instruction function 3 field
    signal funct7           : std_logic_vector(6  downto 0);    -- instruction function 7 field
    signal branch_hf        : std_logic;                        -- branch help field
    signal branch_type_i    : std_logic_vector(3  downto 0);    -- branch type internal
    signal imm_src          : std_logic_vector(4  downto 0);    -- immediate source selecting
    -- nf_control_unit
    component nf_control_unit
        port 
        (
            instr_type  : in    std_logic_vector(1 downto 0);   -- instruction type
            opcode      : in    std_logic_vector(4 downto 0);   -- operation code field in instruction code
            funct3      : in    std_logic_vector(2 downto 0);   -- funct 3 field in instruction code
            funct7      : in    std_logic_vector(6 downto 0);   -- funct 7 field in instruction code
            imm_src     : out   std_logic_vector(4 downto 0);   -- for selecting immediate data
            srcBsel     : out   std_logic;                      -- for selecting srcB ALU
            res_sel     : out   std_logic;                      -- for selecting result
            branch_type : out   std_logic_vector(3 downto 0);   -- for executing branch instructions
            branch_hf   : out   std_logic;                      -- branch help field
            branch_src  : out   std_logic;                      -- for selecting branch source (JALR)
            we_rf       : out   std_logic;                      -- write enable signal for register file    
            we_dm       : out   std_logic;                      -- write enable signal for data memory and other's
            rf_src      : out   std_logic;                      -- write data select for register file
            size_dm     : out   std_logic_vector(1 downto 0);   -- size for load/store instructions
            ALU_Code    : out   std_logic_vector(3 downto 0)    -- output code for ALU unit
        );
    end component;
    -- nf_sign_ex
    component nf_sign_ex
        port 
        (
            imm_data_i  : in    std_logic_vector(11 downto 0);  -- immediate data in i-type instruction
            imm_data_u  : in    std_logic_vector(19 downto 0);  -- immediate data in u-type instruction
            imm_data_b  : in    std_logic_vector(11 downto 0);  -- immediate data in b-type instruction
            imm_data_s  : in    std_logic_vector(11 downto 0);  -- immediate data in s-type instruction
            imm_data_j  : in    std_logic_vector(19 downto 0);  -- immediate data in j-type instruction
            imm_src     : in    std_logic_vector(4  downto 0);  -- selection immediate data input
            imm_ex      : out   std_logic_vector(31 downto 0)   -- extended immediate data
        );
    end component;
    -- nf_branch_unit
    component nf_branch_unit
        port 
        (
            branch_type : in    std_logic_vector(3  downto 0);  -- from control unit, '1 if branch instruction
            branch_hf   : in    std_logic;                      -- branch help field
            d1          : in    std_logic_vector(31 downto 0);  -- from register file (rd1)
            d2          : in    std_logic_vector(31 downto 0);  -- from register file (rd2)
            pc_src      : out   std_logic                       -- next program counter
        );
    end component;
begin

    branch_type <= branch_type_i;
    -- shamt value in instruction
    shamt <= instr(24 downto 20);
    -- register file wires
    ra1 <= instr(19  downto 15);
    ra2 <= instr(24  downto 20);
    wa3 <= instr(11  downto  7);
    -- operation code, funct3 and funct7 field's in instruction
    instr_type <= instr(1  downto  0);
    opcode     <= instr(6  downto  2);
    funct3     <= instr(14 downto 12);
    funct7     <= instr(31 downto 25);
    -- immediate data in instruction
    imm_data_i <= instr(31 downto 20);
    imm_data_u <= instr(31 downto 12);
    imm_data_b <= instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8);
    imm_data_s <= instr(31 downto 25) & instr(11 downto 7);
    imm_data_j <= instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21);

    -- creating control unit for cpu
    nf_control_unit_0 : nf_control_unit 
    port map
    (
        instr_type      => instr_type,      -- instruction type
        opcode          => opcode,          -- operation code field in instruction code
        funct3          => funct3,          -- funct 3 field in instruction code
        funct7          => funct7,          -- funct 7 field in instruction code
        srcBsel         => srcB_sel,        -- for selecting srcB ALU
        res_sel         => res_sel,         -- for selecting result
        branch_type     => branch_type_i,   -- branch type 
        branch_hf       => branch_hf,       -- branch help field
        branch_src      => branch_src,      -- for selecting branch source (JALR)
        we_rf           => we_rf,           -- write enable signal for register file
        we_dm           => we_dm_en,        -- write enable signal for data memory and others
        rf_src          => rf_src,          -- write data select for register file
        imm_src         => imm_src,         -- selection immediate data input
        size_dm         => size_dm,         -- size for load/store instructions
        ALU_Code        => ALU_Code         -- output code for ALU unit
    );
    -- creating sign extending unit
    nf_sign_ex_0 : nf_sign_ex 
    port map
    (
        imm_data_i      => imm_data_i,      -- immediate data in i-type instruction
        imm_data_u      => imm_data_u,      -- immediate data in u-type instruction
        imm_data_b      => imm_data_b,      -- immediate data in b-type instruction
        imm_data_s      => imm_data_s,      -- immediate data in s-type instruction
        imm_data_j      => imm_data_j,      -- immediate data in j-type instruction
        imm_src         => imm_src,         -- selection immediate data input
        imm_ex          => ext_data         -- extended immediate data
    );
    -- creating branch unit
    nf_branch_unit_0 : nf_branch_unit 
    port map
    (
        branch_type     => branch_type_i,   -- from control unit, '1 if branch instruction
        d1              => rd1,             -- from register file (rd1)
        d2              => rd2,             -- from register file (rd2)
        branch_hf       => branch_hf,       -- branch help field
        pc_src          => pc_src           -- next program counter
    );

end rtl; -- nf_i_du
