--
-- File            :   nf_cpu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   SystemVerilog
-- Description     :   This is cpu unit
-- Copyright(c)    :   2018 - 2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_cpu is
    port 
    (
        -- clock and reset
        clk         : in    std_logic;                      -- clock
        resetn      : in    std_logic;                      -- reset
        cpu_en      : in    std_logic;                      -- cpu enable signal
        -- instruction memory
        instr_addr  : out   std_logic_vector(31 downto 0);  -- instruction address
        instr       : in    std_logic_vector(31 downto 0);  -- instruction data
        -- data memory and other's
        addr_dm     : out   std_logic_vector(31 downto 0);  -- data memory address
        we_dm       : out   std_logic;                      -- data memory write enable
        wd_dm       : out   std_logic_vector(31 downto 0);  -- data memory write data
        rd_dm       : in    std_logic_vector(31 downto 0);  -- data memory read data
        -- for debug
        reg_addr    : in    std_logic_vector(4  downto 0);  -- register address
        reg_data    : out   std_logic_vector(31 downto 0)   -- register data
    );
end nf_cpu;

architecture rtl of nf_cpu is
    -- program counter wires
    signal pc_i         :   std_logic_vector(31 downto 0);  -- program counter -> instruction memory address
    signal pc_nb        :   std_logic_vector(31 downto 0);  -- program counter for non branch instructions
    signal pc_b         :   std_logic_vector(31 downto 0);  -- program counter for branch instructions
    signal pc_src       :   std_logic;                      -- program counter selecting pc_nb or pc_b
    signal instr_addr_i :   std_logic_vector(31 downto 0);  -- program counter internal
    -- register file wires
    signal ra1          :   std_logic_vector(4  downto 0);  -- read address 1 from RF
    signal rd1          :   std_logic_vector(31 downto 0);  -- read data 1 from RF
    signal ra2          :   std_logic_vector(4  downto 0);  -- read address 2 from RF
    signal rd2          :   std_logic_vector(31 downto 0);  -- read data 2 from RF
    signal wa3          :   std_logic_vector(4  downto 0);  -- write address for RF
    signal wd3          :   std_logic_vector(31 downto 0);  -- write data for RF
    signal we_rf        :   std_logic;                      -- write enable for RF
    signal rf_src       :   std_logic;                      -- register file source
    signal we_rf_mod    :   std_logic;                      -- write enable for RF with cpu enable signal
    -- sign extend wires
    signal imm_data_i   :   std_logic_vector(11 downto 0);  -- immediate data for i-type commands
    signal imm_data_u   :   std_logic_vector(19 downto 0);  -- immediate data for u-type commands
    signal imm_data_b   :   std_logic_vector(11 downto 0);  -- immediate data for b-type commands
    signal imm_data_s   :   std_logic_vector(11 downto 0);  -- immediate data for s-type commands
    signal ext_data     :   std_logic_vector(31 downto 0);  -- sign extended data
    -- ALU wires
    signal srcA         :   std_logic_vector(31 downto 0);  -- source A for ALU
    signal srcB         :   std_logic_vector(31 downto 0);  -- source B for ALU
    signal shamt        :   std_logic_vector(4  downto 0);  -- for operations with shift
    signal ALU_Code     :   std_logic_vector(2  downto 0);  -- code for ALU
    signal result       :   std_logic_vector(31 downto 0);  -- result of ALU operation
    -- control unit wires
    signal opcode       :   std_logic_vector(6  downto 0);  -- opcode instruction field
    signal funct3       :   std_logic_vector(2  downto 0);  -- funct 3 instruction field
    signal funct7       :   std_logic_vector(6  downto 0);  -- funct 7 instruction field
    signal branch_type  :   std_logic;                      -- branch type
    signal branch_hf    :   std_logic;                      -- branch help field
    signal imm_src      :   std_logic_vector(1  downto 0);  -- immediate data selecting
    signal srcBsel      :   std_logic;                      -- source B for ALU selecting
    -- data memory and other's
    signal we_dm_en     :   std_logic;                      -- write enable for data memory
    -- component definition
    -- nf_alu
    component nf_alu
        port 
        (
            srcA        : in    std_logic_vector(31 downto 0);  -- source A for ALU unit
            srcB        : in    std_logic_vector(31 downto 0);  -- source B for ALU unit
            shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
            ALU_Code    : in    std_logic_vector(2  downto 0);  -- ALU code from control unit
            result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
        );
    end component;
    -- nf_branch_unit
    component nf_branch_unit
        port 
        (
            branch_type : in    std_logic;                      -- from control unit, '1 if branch instruction
            branch_hf   : in    std_logic;                      -- branch help field
            d1          : in    std_logic_vector(31 downto 0);  -- from register file (rd1)
            d2          : in    std_logic_vector(31 downto 0);  -- from register file (rd2)
            pc_src      : out   std_logic                       -- next program counter
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
            imm_src     : in    std_logic_vector(1  downto 0);  -- selection immediate data input
            imm_ex      : out   std_logic_vector(31 downto 0)   -- extended immediate data
        );
    end component;
    -- nf_reg_file
    component nf_reg_file
        port 
        (
            clk     : in    std_logic;                      -- clock
            ra1     : in    std_logic_vector(4  downto 0);  -- read address 1
            rd1     : out   std_logic_vector(31 downto 0);  -- read data 1
            ra2     : in    std_logic_vector(4  downto 0);  -- read address 2
            rd2     : out   std_logic_vector(31 downto 0);  -- read data 2
            wa3     : in    std_logic_vector(4  downto 0);  -- write address 
            wd3     : in    std_logic_vector(31 downto 0);  -- write data
            we3     : in    std_logic;                      -- write enable signal
            ra0     : in    std_logic_vector(4  downto 0);  -- read address 0
            rd0     : out   std_logic_vector(31 downto 0)   -- read data 0
    
        );
    end component;
    -- nf_control_unit
    component nf_control_unit
        port 
        (
            opcode      : in    std_logic_vector(6 downto 0);   -- operation code field in instruction code
            funct3      : in    std_logic_vector(2 downto 0);   -- funct 3 field in instruction code
            funct7      : in    std_logic_vector(6 downto 0);   -- funct 7 field in instruction code
            imm_src     : out   std_logic_vector(1 downto 0);   -- for selecting immediate data
            srcBsel     : out   std_logic;                      -- for selecting srcB ALU
            branch_type : out   std_logic;                      -- for executing branch instructions
            branch_hf   : out   std_logic;                      -- branch help field
            we_rf       : out   std_logic;                      -- write enable signal for register file    
            we_dm       : out   std_logic;                      -- write enable signal for data memory and other's
            rf_src      : out   std_logic;                      -- write data select for register file
            ALU_Code    : out   std_logic_vector(2 downto 0)    -- output code for ALU unit
        );
    end component;
    -- nf_register_we
    component nf_register_we
        generic
        (
            width : integer := 1
        );
        port 
        (
            clk     : in    std_logic;                          -- clock
            resetn  : in    std_logic;                          -- reset
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component;

begin
    -- register's address finding from instruction
    ra1 <= instr(19 downto 15);
    ra2 <= instr(24 downto 20);
    wa3 <= instr(11 downto  7);
    we_rf_mod <= we_rf and cpu_en;
    -- shamt value in instruction
    shamt <= instr(24 downto 20);
    -- operation code, funct3 and funct7 field's in instruction
    opcode <= instr(6  downto  0);
    funct3 <= instr(14 downto 12);
    funct7 <= instr(31 downto 25);
    -- immediate data in instruction
    imm_data_i <= instr(31 downto 20);
    imm_data_u <= instr(31 downto 12);
    imm_data_b <= instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8);
    imm_data_s <= instr(31 downto 25) & instr(11 downto 7);
    -- ALU wire's
    wd3  <= rd_dm when rf_src else result;
    srcA <= rd1;
    srcB <= rd2 when srcBsel else ext_data;
    -- data memory assign's and other's
    addr_dm <= result;
    wd_dm   <= rd2;
    we_dm   <= we_dm_en and cpu_en;
    -- next program counter value for not branch command
    pc_nb <= instr_addr_i + 4;
    -- next program counter value for branch command
    pc_b  <= instr_addr_i + (ext_data(30 downto 0) & '0');
    -- finding next program counter value
    pc_i  <= pc_b when pc_src else pc_nb;
    -- instruction address assigning
    instr_addr <= instr_addr_i;

    -- creating one program counter
    PC: nf_register_we 
    generic map 
    (
        width       => 32 
    ) 
    port map    
    (
        clk         => clk,             -- clock
        resetn      => resetn,          -- reset 
        datai       => pc_i,            -- input data
        datao       => instr_addr_i,    -- output data
        we          => cpu_en           -- write enable
    );
    -- creating one register file
    nf_reg_file_0: nf_reg_file 
    port map    
    (
        clk         => clk,             -- clock
        ra1         => ra1,             -- read address 1
        rd1         => rd1,             -- read data 1
        ra2         => ra2,             -- read address 2
        rd2         => rd2,             -- read data 2
        wa3         => wa3,             -- write address 
        wd3         => wd3,             -- write data
        we3         => we_rf_mod,       -- write enable signal
        ra0         => reg_addr,        -- read address 0
        rd0         => reg_data         -- read data 0
    );
    -- creating one ALU unit
    nf_alu_0: nf_alu 
    port map    
    (
        srcA        => srcA,            -- source A for ALU unit
        srcB        => srcB,            -- source B for ALU unit
        shamt       => shamt,           -- for shift operation
        ALU_Code    => ALU_Code,        -- ALU code from control unit
        result      => result           -- result of ALU operation
    );
    -- creating one control unit for cpu
    nf_control_unit_0: nf_control_unit 
    port map    
    (
        opcode      => opcode,          -- operation code field in instruction code
        funct3      => funct3,          -- funct 3 field in instruction code
        funct7      => funct7,          -- funct 7 field in instruction code
        imm_src     => imm_src,         -- for selecting immediate data
        srcBsel     => srcBsel,         -- for selecting srcB ALU
        branch_type => branch_type,     -- for executing branch instructions
        branch_hf   => branch_hf,       -- branch help field
        we_rf       => we_rf,           -- write enable signal for register file
        we_dm       => we_dm_en,        -- write enable signal for data memory and other's
        rf_src      => rf_src,          -- write data select for register file
        ALU_Code    => ALU_Code         -- output code for ALU unit
    );
    -- creating one  branch unit
    nf_branch_unit_0: nf_branch_unit 
    port map    
    (
        branch_type => branch_type,     -- from control unit, '1 if branch instruction
        branch_hf   => branch_hf,       -- branch help field
        d1          => rd1,             -- from register file (rd1)
        d2          => rd2,             -- from register file (rd2)
        pc_src      => pc_src           -- next program counter selection
    );
    -- creating one sign extending unit
    nf_sign_ex_0: nf_sign_ex 
    port map    
    (
        imm_data_i  => imm_data_i,      -- immediate data in i-type instruction
        imm_data_u  => imm_data_u,      -- immediate data in u-type instruction
        imm_data_b  => imm_data_b,      -- immediate data in b-type instruction
        imm_data_s  => imm_data_s,      -- immediate data in s-type instruction
        imm_src     => imm_src,         -- selection immediate data input
        imm_ex      => ext_data         -- extended immediate data
    );

end rtl; -- nf_cpu
