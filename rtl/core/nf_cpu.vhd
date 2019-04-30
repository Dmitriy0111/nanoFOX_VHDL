--
-- File            :   nf_cpu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is cpu unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;
use nf.nf_help_pkg.all;
use nf.nf_cpu_def.all;

entity nf_cpu is
    generic
    (
        ver         : string := "1.1"
    );
    port
    (
        -- clock and reset
        clk         : in    std_logic;                      -- clk  
        resetn      : in    std_logic;                      -- resetn
        -- instruction memory (IF)
        addr_i      : out   std_logic_vector(31 downto 0);  -- address instruction memory
        rd_i        : in    std_logic_vector(31 downto 0);  -- read instruction memory
        wd_i        : out   std_logic_vector(31 downto 0);  -- write instruction memory
        we_i        : out   std_logic;                      -- write enable instruction memory signal
        size_i      : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_i       : out   std_logic;                      -- request instruction memory signal
        req_ack_i   : in    std_logic;                      -- request acknowledge instruction memory signal
        -- data memory and other's
        addr_dm     : out   std_logic_vector(31 downto 0);  -- address data memory
        rd_dm       : in    std_logic_vector(31 downto 0);  -- read data memory
        wd_dm       : out   std_logic_vector(31 downto 0);  -- write data memory
        we_dm       : out   std_logic;                      -- write enable data memory signal
        size_dm     : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_dm      : out   std_logic;                      -- request data memory signal
        req_ack_dm  : in    std_logic                       -- request acknowledge data memory signal
    );
end nf_cpu;

architecture rtl of nf_cpu is
    --
    signal addr_i_i         :   std_logic_vector(31 downto 0);  -- address instruction memory internal
    -- program counter wires
    signal pc_branch        :   std_logic_vector(31 downto 0);  -- program counter branch value
    signal pc_src           :   std_logic;                      -- program counter source
    signal branch_type      :   std_logic_vector(3  downto 0);  -- branch type
    -- register file wires
    signal wa3              :   std_logic_vector(4  downto 0);  -- write address for register file
    signal wd3              :   std_logic_vector(31 downto 0);  -- write data for register file
    signal we_rf            :   std_logic;                      -- write enable for register file
    --hazard's wires
    signal cmp_d1           :   std_logic_vector(31 downto 0);  -- compare data 1 ( bypass unit )
    signal cmp_d2           :   std_logic_vector(31 downto 0);  -- compare data 2 ( bypass unit )
    signal stall_if         :   std_logic;                      -- stall fetch stage
    signal stall_id         :   std_logic;                      -- stall decode stage
    signal stall_iexe       :   std_logic;                      -- stall execution stage
    signal stall_imem       :   std_logic;                      -- stall memory stage
    signal stall_iwb        :   std_logic;                      -- stall write back stage
    signal flush_iexe       :   std_logic;                      -- flush execution stage

    signal lsu_busy         :   std_logic;                      -- load store unit busy

    signal rd1_i_exu        :   std_logic_vector(31 downto 0);  -- data for execution stage ( bypass unit )
    signal rd2_i_exu        :   std_logic_vector(31 downto 0);  -- data for execution stage ( bypass unit )
    ----------------------------------------------
    --         Instruction Fetch  stage         --
    ----------------------------------------------
    signal instr_if         :   std_logic_vector(31 downto 0);  -- instruction fetch
    ----------------------------------------------
    --         Instruction Decode stage         --
    ----------------------------------------------
    signal instr_id         :   std_logic_vector(31 downto 0);  -- instruction ( decode stage )
    signal pc_id            :   std_logic_vector(31 downto 0);  -- program counter ( decode stage )
    signal wa3_id           :   std_logic_vector(4  downto 0);  -- write address for register file ( decode stage )
    signal ra1_id           :   std_logic_vector(4  downto 0);  -- read address 1 from register file ( decode stage )
    signal ra2_id           :   std_logic_vector(4  downto 0);  -- read address 2 from register file ( decode stage )
    signal ext_data_id      :   std_logic_vector(31 downto 0);  -- extended immediate data ( decode stage )
    signal rd1_id           :   std_logic_vector(31 downto 0);  -- read data 1 from register file ( decode stage )
    signal rd2_id           :   std_logic_vector(31 downto 0);  -- read data 2 from register file ( decode stage )
    signal srcB_sel_id      :   std_logic_vector(0  downto 0);  -- source B selection ( decode stage )
    signal shift_sel_id     :   std_logic_vector(0  downto 0);  -- for selecting shift input ( decode stage )
    signal res_sel_id       :   std_logic_vector(0  downto 0);  -- result select ( decode stage )
    signal we_rf_id         :   std_logic_vector(0  downto 0);  -- write enable register file ( decode stage )
    signal we_dm_id         :   std_logic_vector(0  downto 0);  -- write enable data memory ( decode stage )
    signal rf_src_id        :   std_logic_vector(0  downto 0);  -- register file source ( decode stage )
    signal ALU_Code_id      :   std_logic_vector(3  downto 0);  -- code for execution unit ( decode stage )
    signal shamt_id         :   std_logic_vector(4  downto 0);  -- shift value for execution unit ( decode stage )
    signal branch_src       :   std_logic_vector(0  downto 0);  -- program counter selection
    signal size_dm_id       :   std_logic_vector(1  downto 0);  -- size for load/store instructions ( decode stage )
    ----------------------------------------------
    --       Instruction execution stage        --
    ----------------------------------------------
    signal instr_iexe       :   std_logic_vector(31 downto 0);  -- instruction ( execution stage )
    signal wa3_iexe         :   std_logic_vector(4  downto 0);  -- write address for register file ( execution stage )
    signal ra1_iexe         :   std_logic_vector(4  downto 0);  -- read address 1 from register file ( execution stage )
    signal ra2_iexe         :   std_logic_vector(4  downto 0);  -- read address 2 from register file ( execution stage )
    signal ext_data_iexe    :   std_logic_vector(31 downto 0);  -- extended immediate data ( execution stage )
    signal rd1_iexe         :   std_logic_vector(31 downto 0);  -- read data 1 from register file ( execution stage )
    signal rd2_iexe         :   std_logic_vector(31 downto 0);  -- read data 2 from register file ( execution stage )
    signal pc_iexe          :   std_logic_vector(31 downto 0);  -- program counter value ( execution stage )
    signal srcB_sel_iexe    :   std_logic_vector(0  downto 0);  -- source B selection ( execution stage )
    signal shift_sel_iexe   :   std_logic_vector(0  downto 0);  -- for selecting shift input ( execution stage )
    signal res_sel_iexe     :   std_logic_vector(0  downto 0);  -- result select ( execution stage )
    signal we_rf_iexe       :   std_logic_vector(0  downto 0);  -- write enable register file ( execution stage )
    signal we_dm_iexe       :   std_logic_vector(0  downto 0);  -- write enable data memory ( execution stage )
    signal rf_src_iexe      :   std_logic_vector(0  downto 0);  -- register file source ( execution stage )
    signal ALU_Code_iexe    :   std_logic_vector(3  downto 0);  -- code for execution unit ( execution stage )
    signal shamt_iexe       :   std_logic_vector(4  downto 0);  -- shift value for execution unit ( execution stage )
    signal size_dm_iexe     :   std_logic_vector(1  downto 0);  -- size for load/store instructions ( execution stage )
    signal result_iexe      :   std_logic_vector(31 downto 0);  -- result from execution unit ( execution stage )
    signal result_iexe_e    :   std_logic_vector(31 downto 0);  -- selected result ( execution stage )
    ----------------------------------------------
    --       Instruction memory stage           --
    ----------------------------------------------
    signal instr_imem       :   std_logic_vector(31 downto 0);  -- instruction ( memory stage )
    signal result_imem      :   std_logic_vector(31 downto 0);  -- result operation ( memory stage )
    signal we_dm_imem       :   std_logic_vector(0  downto 0);  -- write enable data memory ( memory stage )
    signal rd2_imem         :   std_logic_vector(31 downto 0);  -- read data 2 from register file ( memory stage )
    signal rf_src_imem      :   std_logic_vector(0  downto 0);  -- register file source ( memory stage )
    signal wa3_imem         :   std_logic_vector(4  downto 0);  -- write address for register file ( memory stage )
    signal we_rf_imem       :   std_logic_vector(0  downto 0);  -- write enable register file ( memory stage )
    signal size_dm_imem     :   std_logic_vector(1  downto 0);  -- size for load/store instructions ( memory stage )
    ----------------------------------------------
    --       Instruction write back stage       --
    ----------------------------------------------
    signal instr_iwb        :   std_logic_vector(31 downto 0);  -- instruction ( write back stage )
    signal wa3_iwb          :   std_logic_vector(4  downto 0);  -- write address for register file ( write back stage )
    signal we_rf_iwb        :   std_logic_vector(0  downto 0);  -- write enable for register file ( write back stage )
    signal rf_src_iwb       :   std_logic_vector(0  downto 0);  -- register file source ( write back stage )
    signal result_iwb       :   std_logic_vector(31 downto 0);  -- result operation ( write back stage )
    signal wd_iwb           :   std_logic_vector(31 downto 0);  -- write data ( write back stage )
    signal rd_dm_iwb        :   std_logic_vector(31 downto 0);  -- read data from data memory ( write back stage )
    -- components
    -- nf_i_fu
    component nf_i_fu
        port
        (
            -- clock and reset
            clk         : in   std_logic;                       -- clock
            resetn      : in   std_logic;                       -- reset
            -- program counter inputs   
            pc_branch   : in   std_logic_vector(31 downto 0);   -- program counter branch value from decode stage
            pc_src      : in   std_logic;                       -- next program counter source
            branch_type : in   std_logic_vector(3  downto 0);   -- branch type
            stall_if    : in   std_logic;                       -- stalling instruction fetch stage
            instr_if    : out  std_logic_vector(31 downto 0);   -- instruction fetch
            -- memory inputs/outputs
            addr_i      : out  std_logic_vector(31 downto 0);   -- address instruction memory
            rd_i        : in   std_logic_vector(31 downto 0);   -- read instruction memory
            wd_i        : out  std_logic_vector(31 downto 0);   -- write instruction memory
            we_i        : out  std_logic;                       -- write enable instruction memory signal
            size_i      : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
            req_i       : out  std_logic;                       -- request instruction memory signal
            req_ack_i   : in   std_logic                        -- request acknowledge instruction memory signal
        );
    end component;
    -- nf_i_du
    component nf_i_du
        port 
        (
            instr       : in    std_logic_vector(31 downto 0);  -- Instruction input
            ext_data    : out   std_logic_vector(31 downto 0);  -- decoded extended data
            srcB_sel    : out   std_logic;                      -- decoded source B selection for ALU
            shift_sel   : out   std_logic;                      -- for selecting shift input
            res_sel     : out   std_logic;                      -- for selecting result
            ALU_Code    : out   std_logic_vector(3  downto 0);  -- decoded ALU code
            shamt       : out   std_logic_vector(4  downto 0);  -- decoded for shift command's
            ra1         : out   std_logic_vector(4  downto 0);  -- decoded read address 1 for register file
            rd1         : in    std_logic_vector(31 downto 0);  -- read data 1 from register file
            ra2         : out   std_logic_vector(4  downto 0);  -- decoded read address 2 for register file
            rd2         : in    std_logic_vector(31 downto 0);  -- read data 2 from register file
            wa3         : out   std_logic_vector(4  downto 0);  -- decoded write address 2 for register file
            pc_src      : out   std_logic;                      -- decoded next program counter value enable
            we_rf       : out   std_logic;                      -- decoded write register file
            we_dm_en    : out   std_logic;                      -- decoded write data memory
            rf_src      : out   std_logic;                      -- decoded source register file signal
            size_dm     : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
            branch_src  : out   std_logic;                      -- for selecting branch source (JALR)
            branch_type : out   std_logic_vector(3  downto 0)   -- branch type
        );
    end component;
    -- nf_i_exu
    component nf_i_exu
        port 
        (
            rd1         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port1)
            rd2         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port2)
            ext_data    : in    std_logic_vector(31 downto 0);  -- sign extended immediate data
            srcB_sel    : in    std_logic;                      -- source enable signal for ALU
            shift_sel   : in    std_logic;                      -- for selecting shift input
            shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
            ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
            result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
        );
    end component;
    -- nf_i_lsu
    component nf_i_lsu
        port 
        (
            -- clock and reset
            clk             : in    std_logic;                      -- clock
            resetn          : in    std_logic;                      -- reset
            -- pipeline wires
            result_imem     : in    std_logic_vector(31 downto 0);  -- result from imem stage
            rd2_imem        : in    std_logic_vector(31 downto 0);  -- read data 2 from imem stage
            we_dm_imem      : in    std_logic;                      -- write enable data memory from imem stage
            rf_src_imem     : in    std_logic;                      -- register file source enable from imem stage
            size_dm_imem    : in    std_logic_vector(1  downto 0);  -- size data memory from imem stage
            rd_dm_iwb       : out   std_logic_vector(31 downto 0);  -- read data for write back stage
            lsu_busy        : out   std_logic;                      -- load store unit busy
            -- data memory and other's
            addr_dm         : out   std_logic_vector(31 downto 0);  -- address data memory
            rd_dm           : in    std_logic_vector(31 downto 0);  -- read data memory
            wd_dm           : out   std_logic_vector(31 downto 0);  -- write data memory
            we_dm           : out   std_logic;                      -- write enable data memory signal
            size_dm         : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
            req_dm          : out   std_logic;                      -- request data memory signal
            req_ack_dm      : in    std_logic                       -- request acknowledge data memory signal
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
            we3     : in    std_logic                       -- write enable signal
        );
    end component;
    -- nf_hz_bypass_unit
    component nf_hz_bypass_unit
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
    end component;
    -- nf_hz_stall_unit
    component nf_hz_stall_unit
        port 
        (
            -- scan wires
            we_rf_imem  : in    std_logic;                      -- write enable register from memory stage
            wa3_iexe    : in    std_logic_vector(4 downto 0);   -- write address from execution stage
            wa3_imem    : in    std_logic_vector(4 downto 0);   -- write address from execution stage
            we_rf_iexe  : in    std_logic;                      -- write enable register from memory stage
            rf_src_iexe : in    std_logic;                      -- register source from execution stage
            ra1_id      : in    std_logic_vector(4 downto 0);   -- read address 1 from decode stage
            ra2_id      : in    std_logic_vector(4 downto 0);   -- read address 2 from decode stage
            branch_type : in    std_logic_vector(3 downto 0);   -- branch type
            we_dm_imem  : in    std_logic;                      -- write enable data memory from memory stage
            req_ack_dm  : in    std_logic;                      -- request acknowledge data memory
            req_ack_i   : in    std_logic;                      -- request acknowledge instruction
            rf_src_imem : in    std_logic;                      -- register source from memory stage
            lsu_busy    : in    std_logic;                      -- load store unit busy
            -- control wires
            stall_if    : out   std_logic;                      -- stall fetch stage
            stall_id    : out   std_logic;                      -- stall decode stage
            stall_iexe  : out   std_logic;                      -- stall execution stage
            stall_imem  : out   std_logic;                      -- stall memory stage
            stall_iwb   : out   std_logic;                      -- stall write back stage
            flush_iexe  : out   std_logic                       -- flush execution stage
        );
    end component;
    -- nf_register_we
    component nf_register_we
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component; 
    -- nf_register_we_clr
    component nf_register_we_clr
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            clr     : in    std_logic;                          -- clear register
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component;  
begin

    -- next program counter value for branch command
    pc_branch  <= ( pc_id + ( ext_data_id(30 downto 0) & '0' ) - 4 ) when ( not branch_src(0) ) else ( rd1_id + ( ext_data_id(30 downto 0) & '0' ) );
    result_iexe_e <= result_iexe when ( res_sel_iexe(0) = RES_ALU ) else pc_iexe;
    wa3    <= wa3_iwb;
    wd3    <= wd_iwb;
    wd_iwb <= rd_dm_iwb when rf_src_iwb(0) else result_iwb;
    we_rf  <= we_rf_iwb(0);
    addr_i <= addr_i_i;
    -- if2id
    instr_if_id         : nf_register_we     generic map ( 32 ) port map ( clk , resetn , not stall_id   ,              instr_if      , instr_id       );
    pc_if_id            : nf_register_we     generic map ( 32 ) port map ( clk , resetn , not stall_id   ,              addr_i_i      , pc_id          );
    -- id2iexe 
    wa3_id_iexe         : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_iexe , flush_iexe , wa3_id        , wa3_iexe       );
    ra1_id_iexe         : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_iexe , flush_iexe , ra1_id        , ra1_iexe       );
    ra2_id_iexe         : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_iexe , flush_iexe , ra2_id        , ra2_iexe       );
    shamt_id_iexe       : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_iexe , flush_iexe , shamt_id      , shamt_iexe     );
    sign_ex_id_iexe     : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iexe , flush_iexe , ext_data_id   , ext_data_iexe  );
    rd1_id_iexe         : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iexe , flush_iexe , rd1_id        , rd1_iexe       );
    rd2_id_iexe         : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iexe , flush_iexe , rd2_id        , rd2_iexe       );
    pc_id_iexe          : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iexe , flush_iexe , pc_id         , pc_iexe        );
    size_dm_id_iexe     : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_iexe , flush_iexe , size_dm_id    , size_dm_iexe   );
    srcB_sel_id_iexe    : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , srcB_sel_id   , srcB_sel_iexe  );
    shift_sel_id_iexe   : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , shift_sel_id  , shift_sel_iexe );
    res_sel_id_iexe     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , res_sel_id    , res_sel_iexe   );
    we_rf_id_iexe       : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , we_rf_id      , we_rf_iexe     );
    we_dm_id_iexe       : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , we_dm_id      , we_dm_iexe     );
    rf_src_id_iexe      : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , rf_src_id     , rf_src_iexe    );
    ALU_Code_id_iexe    : nf_register_we_clr generic map (  4 ) port map ( clk , resetn , not stall_iexe , flush_iexe , ALU_Code_id   , ALU_Code_iexe  );
    -- iexe2imem
    we_dm_iexe_imem     : nf_register_we     generic map (  1 ) port map ( clk , resetn , not stall_imem ,              we_dm_iexe    , we_dm_imem     );
    we_rf_iexe_imem     : nf_register_we     generic map (  1 ) port map ( clk , resetn , not stall_imem ,              we_rf_iexe    , we_rf_imem     );
    rf_src_iexe_imem    : nf_register_we     generic map (  1 ) port map ( clk , resetn , not stall_imem ,              rf_src_iexe   , rf_src_imem    );
    size_dm_iexe_imem   : nf_register_we     generic map (  2 ) port map ( clk , resetn , not stall_imem ,              size_dm_iexe  , size_dm_imem   );
    wa3_iexe_imem       : nf_register_we     generic map (  5 ) port map ( clk , resetn , not stall_imem ,              wa3_iexe      , wa3_imem       );
    rd2_i_exu_imem      : nf_register_we     generic map ( 32 ) port map ( clk , resetn , not stall_imem ,              rd2_i_exu     , rd2_imem       );
    result_iexe_imem    : nf_register_we     generic map ( 32 ) port map ( clk , resetn , not stall_imem ,              result_iexe_e , result_imem    );
    -- imem2iwb             
    we_rf_imem_iwb      : nf_register_we     generic map (  1 ) port map ( clk , resetn , not stall_iwb  ,              we_rf_imem    , we_rf_iwb      );
    rf_src_imem_iwb     : nf_register_we     generic map (  1 ) port map ( clk , resetn , not stall_iwb  ,              rf_src_imem   , rf_src_iwb     );
    wa3_imem_iwb        : nf_register_we     generic map (  5 ) port map ( clk , resetn , not stall_iwb  ,              wa3_imem      , wa3_iwb        );
    result_imem_iwb     : nf_register_we     generic map ( 32 ) port map ( clk , resetn , not stall_iwb  ,              result_imem   , result_iwb     );
    -- for verification
    -- synthesis translate_off
    instr_id_iexe       : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iexe , flush_iexe , instr_id      , instr_iexe     );
    instr_iexe_imem     : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_imem , '0'        , instr_iexe    , instr_imem     );
    instr_imem_iwb      : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iwb  , '0'        , instr_imem    , instr_iwb      );
    -- synthesis translate_on

    -- creating one instruction fetch unit
    nf_i_fu_0 : nf_i_fu 
    port map
    (
        -- clock and reset
        clk         => clk,             -- clock
        resetn      => resetn,          -- reset
        -- program counter inputs
        pc_branch   => pc_branch,       -- program counter branch value from decode stage
        pc_src      => pc_src,          -- next program counter source
        branch_type => branch_type,     -- branch type
        stall_if    => stall_if,        -- stalling instruction fetch stage
        instr_if    => instr_if,        -- instruction fetch
        -- memory inputs/outputs
        addr_i      => addr_i_i,        -- address instruction memory
        rd_i        => rd_i,            -- read instruction memory
        wd_i        => wd_i,            -- write instruction memory
        we_i        => we_i,            -- write enable instruction memory signal
        size_i      => size_i,          -- size for load/store instructions
        req_i       => req_i,           -- request instruction memory signal
        req_ack_i   => req_ack_i        -- request acknowledge instruction memory signal
    );
    -- creating register file
    nf_reg_file_0 : nf_reg_file 
    port map
    (
        clk     => clk,     -- clock
        ra1     => ra1_id,  -- read address 1
        rd1     => rd1_id,  -- read data 1
        ra2     => ra2_id,  -- read address 2
        rd2     => rd2_id,  -- read data 2
        wa3     => wa3,     -- write address 
        wd3     => wd3,     -- write data
        we3     => we_rf    -- write enable signal
    );
    -- creating instruction decode unit
    nf_i_du_0 : nf_i_du 
    port map
    (
        instr           => instr_id,        -- Instruction input
        ext_data        => ext_data_id,     -- decoded extended data
        srcB_sel        => srcB_sel_id(0),  -- decoded source B selection for ALU
        shift_sel       => shift_sel_id(0), -- for selecting shift input
        res_sel         => res_sel_id(0),   -- for selecting result
        ALU_Code        => ALU_Code_id,     -- decoded ALU code
        shamt           => shamt_id,        -- decoded for shift command's
        ra1             => ra1_id,          -- decoded read address 1 for register file
        rd1             => cmp_d1,          -- read data 1 from register file
        ra2             => ra2_id,          -- decoded read address 2 for register file
        rd2             => cmp_d2,          -- read data 2 from register file
        wa3             => wa3_id,          -- decoded write address 2 for register file
        pc_src          => pc_src,          -- decoded next program counter value enable
        we_rf           => we_rf_id(0),     -- decoded write register file
        we_dm_en        => we_dm_id(0),     -- decoded write data memory
        rf_src          => rf_src_id(0),    -- decoded source register file signal
        size_dm         => size_dm_id,      -- size for load/store instructions
        branch_src      => branch_src(0),   -- for selecting branch source (JALR)
        branch_type     => branch_type      -- branch type
    );
    -- creating instruction execution unit
    nf_i_exu_0 : nf_i_exu 
    port map
    (
        rd1             => rd1_i_exu,           -- read data from reg file (port1)
        rd2             => rd2_i_exu,           -- read data from reg file (port2)
        ext_data        => ext_data_iexe,       -- sign extended immediate data
        srcB_sel        => srcB_sel_iexe(0),    -- source B enable signal for ALU
        shift_sel       => shift_sel_iexe(0),   -- for selecting shift input
        shamt           => shamt_iexe,          -- for shift operations
        ALU_Code        => ALU_Code_iexe,       -- code for ALU
        result          => result_iexe          -- result of ALU operation
    );
    -- creating one load/store unit
    nf_i_lsu_0 : nf_i_lsu 
    port map
    (
        -- clock and reset
        clk             => clk,             -- clock
        resetn          => resetn,          -- reset
        -- pipeline wires
        result_imem     => result_imem,     -- result from imem stage
        rd2_imem        => rd2_imem,        -- read data 2 from imem stage
        we_dm_imem      => we_dm_imem(0),   -- write enable data memory from imem stage
        rf_src_imem     => rf_src_imem(0),  -- register file source enable from imem stage
        size_dm_imem    => size_dm_imem,    -- size data memory from imem stage
        rd_dm_iwb       => rd_dm_iwb,       -- read data for write back stage
        lsu_busy        => lsu_busy,        -- load store unit busy
        -- data memory and other's
        addr_dm         => addr_dm,         -- address data memory
        rd_dm           => rd_dm,           -- read data memory
        wd_dm           => wd_dm,           -- write data memory
        we_dm           => we_dm,           -- write enable data memory signal
        size_dm         => size_dm,         -- size for load/store instructions
        req_dm          => req_dm,          -- request data memory signal
        req_ack_dm      => req_ack_dm       -- request acknowledge data memory signal
    );
    -- creating stall and flush unit (hazard)
    nf_hz_stall_unit_0 : nf_hz_stall_unit 
    port map
    (   
        -- scan wires
        we_rf_imem      => we_rf_imem(0),   -- write enable register from memory stage
        wa3_iexe        => wa3_iexe,        -- write address from execution stage
        wa3_imem        => wa3_imem,        -- write address from memory stage
        we_rf_iexe      => we_rf_iexe(0),   -- write enable register from memory stage
        rf_src_iexe     => rf_src_iexe(0),  -- register source from execution stage
        ra1_id          => ra1_id,          -- read address 1 from decode stage
        ra2_id          => ra2_id,          -- read address 2 from decode stage
        branch_type     => branch_type,     -- branch type
        we_dm_imem      => we_dm_imem(0),   -- write enable data memory from memory stage
        req_ack_dm      => req_ack_dm,      -- request acknowledge data memory
        req_ack_i       => req_ack_i,       -- request acknowledge instruction
        rf_src_imem     => rf_src_imem(0),  -- register source from memory stage
        lsu_busy        => lsu_busy,        -- load store unit busy
        -- control wires
        stall_if        => stall_if,        -- stall fetch stage
        stall_id        => stall_id,        -- stall decode stage
        stall_iexe      => stall_iexe,      -- stall execution stage
        stall_imem      => stall_imem,      -- stall memory stage
        stall_iwb       => stall_iwb,       -- stall write back stage
        flush_iexe      => flush_iexe       -- flush execution stage
    );
    -- creating bypass unit (hazard)
    nf_hz_bypass_unit_0 : nf_hz_bypass_unit 
    port map
    (
        -- scan wires
        wa3_imem        => wa3_imem,        -- write address from mem stage
        we_rf_imem      => we_rf_imem(0),   -- write enable register from mem stage
        wa3_iwb         => wa3_iwb,         -- write address from write back stage
        we_rf_iwb       => we_rf_iwb(0),    -- write enable register from write back stage
        ra1_id          => ra1_id,          -- read address 1 from decode stage
        ra2_id          => ra2_id,          -- read address 2 from decode stage
        ra1_iexe        => ra1_iexe,        -- read address 1 from execution stage
        ra2_iexe        => ra2_iexe,        -- read address 2 from execution stage
        -- bypass inputs
        rd1_iexe        => rd1_iexe,        -- read data 1 from execution stage
        rd2_iexe        => rd2_iexe,        -- read data 2 from execution stage
        result_imem     => result_imem,     -- ALU result from mem stage
        wd_iwb          => wd_iwb,          -- write data from iwb stage
        rd1_id          => rd1_id,          -- read data 1 from decode stage
        rd2_id          => rd2_id,          -- read data 2 from decode stage
        -- bypass outputs
        rd1_i_exu       => rd1_i_exu,       -- bypass data 1 for execution stage
        rd2_i_exu       => rd2_i_exu,       -- bypass data 2 for execution stage
        cmp_d1          => cmp_d1,          -- bypass data 1 for decode stage (branch)
        cmp_d2          => cmp_d2           -- bypass data 2 for decode stage (branch)
    );

end rtl; -- nf_cpu
