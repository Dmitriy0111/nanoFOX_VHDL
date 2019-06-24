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
use nf.nf_components.all;

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
    -- program counter wires
    signal pc_branch        : std_logic_vector(31 downto 0);    -- program counter branch value
    signal last_pc          : std_logic_vector(31 downto 0);    -- last program counter
    signal addr_i_i         : std_logic_vector(31 downto 0);    -- address internal
    signal pc_src           : std_logic;                        -- program counter source
    signal branch_type      : std_logic_vector(3  downto 0);    -- branch type
    -- register file wires
    signal wa3              : std_logic_vector(4  downto 0);    -- write address for register file
    signal wd3              : std_logic_vector(31 downto 0);    -- write data for register file
    signal we_rf            : std_logic;                        -- write enable for register file
    --hazard's wires
    signal cmp_d1           : std_logic_vector(31 downto 0);    -- compare data 1 ( bypass unit )
    signal cmp_d2           : std_logic_vector(31 downto 0);    -- compare data 2 ( bypass unit )
    signal stall_if         : std_logic;                        -- stall fetch stage
    signal stall_id         : std_logic;                        -- stall decode stage
    signal stall_iexe       : std_logic;                        -- stall execution stage
    signal stall_imem       : std_logic;                        -- stall memory stage
    signal stall_iwb        : std_logic;                        -- stall write back stage
    signal flush_id         : std_logic;                        -- flush decode stage
    signal flush_iexe       : std_logic;                        -- flush execution stage
    signal flush_imem       : std_logic;                        -- flush memory stage
    signal flush_iwb        : std_logic;                        -- flush write back stage

    signal rd1_i_exu        : std_logic_vector(31 downto 0);    -- data for execution stage ( bypass unit )
    signal rd2_i_exu        : std_logic_vector(31 downto 0);    -- data for execution stage ( bypass unit )

    -- csr interface
    signal csr_addr         : std_logic_vector(11 downto 0);    -- csr address
    signal csr_rd           : std_logic_vector(31 downto 0);    -- csr read data
    signal csr_wd           : std_logic_vector(31 downto 0);    -- csr write data
    signal csr_cmd          : std_logic_vector(1  downto 0);    -- csr command
    signal csr_wreq         : std_logic;                        -- csr write request
    signal csr_rreq         : std_logic;                        -- csr read request

    signal mtvec_v          : std_logic_vector(31 downto 0);    -- machine trap-handler base address
    signal m_ret_pc         : std_logic_vector(31 downto 0);    -- m return pc value
    signal addr_misalign    : std_logic;                        -- address misaligned signal
    signal l_misaligned     : std_logic;                        -- load misaligned signal
    signal s_misaligned     : std_logic;                        -- store misaligned signal
    ----------------------------------------------
    --         Instruction Fetch  stage         --
    ----------------------------------------------
    signal instr_if         : std_logic_vector(31 downto 0);    -- instruction fetch
    ----------------------------------------------
    --         Instruction Decode stage         --
    ----------------------------------------------
    signal instr_id         : std_logic_vector(31 downto 0);    -- instruction ( decode stage )
    signal pc_id            : std_logic_vector(31 downto 0);    -- program counter ( decode stage )
    signal wa3_id           : std_logic_vector(4  downto 0);    -- write address for register file ( decode stage )
    signal ra1_id           : std_logic_vector(4  downto 0);    -- read address 1 from register file ( decode stage )
    signal ra2_id           : std_logic_vector(4  downto 0);    -- read address 2 from register file ( decode stage )
    signal ext_data_id      : std_logic_vector(31 downto 0);    -- extended immediate data ( decode stage )
    signal rd1_id           : std_logic_vector(31 downto 0);    -- read data 1 from register file ( decode stage )
    signal rd2_id           : std_logic_vector(31 downto 0);    -- read data 2 from register file ( decode stage )
    signal srcA_sel_id      : std_logic_vector(1  downto 0);    -- source A selection ( decode stage )
    signal srcB_sel_id      : std_logic_vector(1  downto 0);    -- source B selection ( decode stage )
    signal shift_sel_id     : std_logic_vector(1  downto 0);    -- for selecting shift input ( decode stage )
    signal res_sel_id       : std_logic_vector(0  downto 0);    -- result select ( decode stage )
    signal we_rf_id         : std_logic_vector(0  downto 0);    -- write enable register file ( decode stage )
    signal we_dm_id         : std_logic_vector(0  downto 0);    -- write enable data memory ( decode stage )
    signal rf_src_id        : std_logic_vector(0  downto 0);    -- register file source ( decode stage )
    signal ALU_Code_id      : std_logic_vector(3  downto 0);    -- code for execution unit ( decode stage )
    signal shamt_id         : std_logic_vector(4  downto 0);    -- shift value for execution unit ( decode stage )
    signal branch_src       : std_logic_vector(0  downto 0);    -- program counter selection
    signal size_dm_id       : std_logic_vector(1  downto 0);    -- size for load/store instructions ( decode stage )
    signal sign_dm_id       : std_logic_vector(0  downto 0);    -- sign extended data memory for load instructions ( decode stage )
    signal csr_addr_id      : std_logic_vector(11 downto 0);    -- csr address ( decode stage )
    signal csr_cmd_id       : std_logic_vector(1  downto 0);    -- csr command ( decode stage )
    signal csr_rreq_id      : std_logic_vector(0  downto 0);    -- read request to csr ( decode stage )
    signal csr_wreq_id      : std_logic_vector(0  downto 0);    -- write request to csr ( decode stage )
    signal csr_sel_id       : std_logic_vector(0  downto 0);    -- csr select ( zimm or rd1 ) ( decode stage )
    signal m_ret_id         : std_logic;                        -- m return
    ----------------------------------------------
    --       Instruction execution stage        --
    ----------------------------------------------
    signal instr_iexe       : std_logic_vector(31 downto 0);    -- instruction ( execution stage )
    signal wa3_iexe         : std_logic_vector(4  downto 0);    -- write address for register file ( execution stage )
    signal ra1_iexe         : std_logic_vector(4  downto 0);    -- read address 1 from register file ( execution stage )
    signal ra2_iexe         : std_logic_vector(4  downto 0);    -- read address 2 from register file ( execution stage )
    signal ext_data_iexe    : std_logic_vector(31 downto 0);    -- extended immediate data ( execution stage )
    signal rd1_iexe         : std_logic_vector(31 downto 0);    -- read data 1 from register file ( execution stage )
    signal rd2_iexe         : std_logic_vector(31 downto 0);    -- read data 2 from register file ( execution stage )
    signal pc_iexe          : std_logic_vector(31 downto 0);    -- program counter value ( execution stage )
    signal srcA_sel_iexe    : std_logic_vector(1  downto 0);    -- source A selection ( execution stage )
    signal srcB_sel_iexe    : std_logic_vector(1  downto 0);    -- source B selection ( execution stage )
    signal shift_sel_iexe   : std_logic_vector(1  downto 0);    -- for selecting shift input ( execution stage )
    signal res_sel_iexe     : std_logic_vector(0  downto 0);    -- result select ( execution stage )
    signal we_rf_iexe       : std_logic_vector(0  downto 0);    -- write enable register file ( execution stage )
    signal we_dm_iexe       : std_logic_vector(0  downto 0);    -- write enable data memory ( execution stage )
    signal rf_src_iexe      : std_logic_vector(0  downto 0);    -- register file source ( execution stage )
    signal ALU_Code_iexe    : std_logic_vector(3  downto 0);    -- code for execution unit ( execution stage )
    signal shamt_iexe       : std_logic_vector(4  downto 0);    -- shift value for execution unit ( execution stage )
    signal size_dm_iexe     : std_logic_vector(1  downto 0);    -- size for load/store instructions ( execution stage )
    signal sign_dm_iexe     : std_logic_vector(0  downto 0);    -- sign extended data memory for load instructions ( execution stage )
    signal result_iexe      : std_logic_vector(31 downto 0);    -- result from execution unit ( execution stage )
    signal result_iexe_e    : std_logic_vector(31 downto 0);    -- selected result ( execution stage )
    signal csr_addr_iexe    : std_logic_vector(11 downto 0);    -- csr address ( execution stage )
    signal csr_cmd_iexe     : std_logic_vector(1  downto 0);    -- csr command ( execution stage )
    signal csr_rreq_iexe    : std_logic_vector(0  downto 0);    -- read request to csr ( execution stage )
    signal csr_wreq_iexe    : std_logic_vector(0  downto 0);    -- write request to csr ( execution stage )
    signal csr_sel_iexe     : std_logic_vector(0  downto 0);    -- csr select ( zimm or rd1 ) ( execution stage )
    signal csr_zimm         : std_logic_vector(4  downto 0);    -- csr zero immediate data ( execution stage )
    ----------------------------------------------
    --       Instruction memory stage           --
    ----------------------------------------------
    signal instr_imem       : std_logic_vector(31 downto 0);    -- instruction ( memory stage )
    signal result_imem      : std_logic_vector(31 downto 0);    -- result operation ( memory stage )
    signal we_dm_imem       : std_logic_vector(0  downto 0);    -- write enable data memory ( memory stage )
    signal rd1_imem         : std_logic_vector(31 downto 0);    -- read data 1 from register file ( memory stage )
    signal rd2_imem         : std_logic_vector(31 downto 0);    -- read data 2 from register file ( memory stage )
    signal rf_src_imem      : std_logic_vector(0  downto 0);    -- register file source ( memory stage )
    signal wa3_imem         : std_logic_vector(4  downto 0);    -- write address for register file ( memory stage )
    signal we_rf_imem       : std_logic_vector(0  downto 0);    -- write enable register file ( memory stage )
    signal size_dm_imem     : std_logic_vector(1  downto 0);    -- size for load/store instructions ( memory stage )
    signal sign_dm_imem     : std_logic_vector(0  downto 0);    -- sign extended data memory for load instructions ( memory stage )
    signal pc_imem          : std_logic_vector(31 downto 0);    -- program counter value ( memory stage )
    ----------------------------------------------
    --       Instruction write back stage       --
    ----------------------------------------------
    signal instr_iwb        : std_logic_vector(31 downto 0);    -- instruction ( write back stage )
    signal wa3_iwb          : std_logic_vector(4  downto 0);    -- write address for register file ( write back stage )
    signal we_rf_iwb        : std_logic_vector(0  downto 0);    -- write enable for register file ( write back stage )
    signal rf_src_iwb       : std_logic_vector(0  downto 0);    -- register file source ( write back stage )
    signal result_iwb       : std_logic_vector(31 downto 0);    -- result operation ( write back stage )
    signal wd_iwb           : std_logic_vector(31 downto 0);    -- write data ( write back stage )
    signal rd_dm_iwb        : std_logic_vector(31 downto 0);    -- read data from data memory ( write back stage )
    signal pc_iwb           : std_logic_vector(31 downto 0);    -- program counter value ( write back stage )
    signal lsu_busy         : std_logic_vector(0  downto 0);    -- load store unit busy
    signal lsu_err          : std_logic;                        -- load store unit error
begin

    -- next program counter value for branch command
    pc_branch  <= ( pc_id + ( ext_data_id(30 downto 0) & '0' ) ) when ( not branch_src(0) ) else ( cmp_d1 + ext_data_id ) and 32X"FFFFFFFE";
    wa3    <= wa3_iwb;
    wd3    <= wd_iwb;
    we_rf  <= we_rf_iwb(0);
    addr_i <= addr_i_i;
    -- connecting csr wires to cpu output
    csr_addr <= csr_addr_iexe;
    csr_zimm <= ra1_iexe;
    csr_wd   <= ( 27B"0" & csr_zimm ) when ( csr_sel_iexe = "1" ) else rd1_i_exu;
    csr_rreq <= csr_rreq_iexe(0);
    csr_wreq <= csr_wreq_iexe(0);
    csr_cmd  <= csr_cmd_iexe;
    -- selecting write data to reg file
    wd_proc : process( all )
    begin
        wd_iwb <= result_iwb;
        case( rf_src_iwb ) is
            when "0"    => wd_iwb <= result_iwb;
            when "1"    => wd_iwb <= rd_dm_iwb;
            when others =>
        end case;
    end process;
    -- selecting data for iexe stage
    result_proc : process( all )
        variable sel : std_logic_vector(1 downto 0);
    begin
        sel := csr_rreq_iexe & res_sel_iexe;
        result_iexe_e <= result_iexe;
        case( sel ) is
            when RES_ALU    => result_iexe_e <= result_iexe;    -- RES_ALU
            when RES_UB     => result_iexe_e <= pc_iexe + 4;    -- RES_UB
            when RES_CSR    => result_iexe_e <= csr_rd;         -- RES_CSR
            when others     =>
        end case;
    end process;

    -- if2id
    instr_if_id         : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_id   , flush_id   , instr_if      , instr_id       );
    pc_if_id            : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_id   , flush_id   , last_pc       , pc_id          );
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
    sign_dm_id_iexe     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , sign_dm_id    , sign_dm_iexe   );
    srcA_sel_id_iexe    : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_iexe , flush_iexe , srcA_sel_id   , srcA_sel_iexe  );
    srcB_sel_id_iexe    : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_iexe , flush_iexe , srcB_sel_id   , srcB_sel_iexe  );
    shift_sel_id_iexe   : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_iexe , flush_iexe , shift_sel_id  , shift_sel_iexe );
    res_sel_id_iexe     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , res_sel_id    , res_sel_iexe   );
    we_rf_id_iexe       : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , we_rf_id      , we_rf_iexe     );
    we_dm_id_iexe       : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , we_dm_id      , we_dm_iexe     );
    rf_src_id_iexe      : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , rf_src_id     , rf_src_iexe    );
    ALU_Code_id_iexe    : nf_register_we_clr generic map (  4 ) port map ( clk , resetn , not stall_iexe , flush_iexe , ALU_Code_id   , ALU_Code_iexe  );
    csr_addr_id_iexe    : nf_register_we_clr generic map ( 12 ) port map ( clk , resetn , not stall_iexe , flush_iexe , csr_addr_id   , csr_addr_iexe  );
    csr_cmd_id_iexe     : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_iexe , flush_iexe , csr_cmd_id    , csr_cmd_iexe   );
    csr_rreq_id_iexe    : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , csr_rreq_id   , csr_rreq_iexe  );
    csr_wreq_id_iexe    : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , csr_wreq_id   , csr_wreq_iexe  );
    csr_sel_id_iexe     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iexe , flush_iexe , csr_sel_id    , csr_sel_iexe   );
    -- iexe2imem
    we_dm_iexe_imem     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_imem , flush_imem , we_dm_iexe    , we_dm_imem     );
    we_rf_iexe_imem     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_imem , flush_imem , we_rf_iexe    , we_rf_imem     );
    rf_src_iexe_imem    : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_imem , flush_imem , rf_src_iexe   , rf_src_imem    );
    sign_dm_iexe_imem   : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_imem , flush_imem , sign_dm_iexe  , sign_dm_imem   );
    size_dm_iexe_imem   : nf_register_we_clr generic map (  2 ) port map ( clk , resetn , not stall_imem , flush_imem , size_dm_iexe  , size_dm_imem   );
    wa3_iexe_imem       : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_imem , flush_imem , wa3_iexe      , wa3_imem       );
    rd1_i_exu_imem      : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_imem , flush_imem , rd1_i_exu     , rd1_imem       );
    rd2_i_exu_imem      : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_imem , flush_imem , rd2_i_exu     , rd2_imem       );
    result_iexe_imem    : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_imem , flush_imem , result_iexe_e , result_imem    );
    pc_iexe_imem        : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_imem , flush_imem , pc_iexe       , pc_imem        );
    -- imem2iwb
    we_rf_imem_iwb      : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iwb  , flush_iwb  , we_rf_imem    , we_rf_iwb      );
    rf_src_imem_iwb     : nf_register_we_clr generic map (  1 ) port map ( clk , resetn , not stall_iwb  , flush_iwb  , rf_src_imem   , rf_src_iwb     );
    wa3_imem_iwb        : nf_register_we_clr generic map (  5 ) port map ( clk , resetn , not stall_iwb  , flush_iwb  , wa3_imem      , wa3_iwb        );
    result_imem_iwb     : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iwb  , flush_iwb  , result_imem   , result_iwb     );
    pc_imem_iwb         : nf_register_we_clr generic map ( 32 ) port map ( clk , resetn , not stall_iwb  , flush_iwb  , pc_imem       , pc_iwb         );
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
        clk             => clk,             -- clock
        resetn          => resetn,          -- reset
        -- program counter inputs
        pc_branch       => pc_branch,       -- program counter branch value from decode stage
        pc_src          => pc_src,          -- next program counter source
        stall_if        => stall_if,        -- stalling instruction fetch stage
        instr_if        => instr_if,        -- instruction fetch
        last_pc         => last_pc,         -- last program_counter
        mtvec_v         => mtvec_v,         -- machine trap-handler base address
        m_ret           => m_ret_id,        -- m return
        m_ret_pc        => m_ret_pc,        -- m return pc value
        addr_misalign   => addr_misalign,   -- address misaligned
        lsu_err         => lsu_err,         -- load store unit error
        -- memory inputs/outputs
        addr_i          => addr_i_i,        -- address instruction memory
        rd_i            => rd_i,            -- read instruction memory
        wd_i            => wd_i,            -- write instruction memory
        we_i            => we_i,            -- write enable instruction memory signal
        size_i          => size_i,          -- size for load/store instructions
        req_i           => req_i,           -- request instruction memory signal
        req_ack_i       => req_ack_i        -- request acknowledge instruction memory signal
    );
    -- creating register file
    nf_reg_file_0 : nf_reg_file 
    port map
    (
        clk             => clk,     -- clock
        ra1             => ra1_id,  -- read address 1
        rd1             => rd1_id,  -- read data 1
        ra2             => ra2_id,  -- read address 2
        rd2             => rd2_id,  -- read data 2
        wa3             => wa3,     -- write address 
        wd3             => wd3,     -- write data
        we3             => we_rf    -- write enable signal
    );
    -- creating instruction decode unit
    nf_i_du_0 : nf_i_du 
    port map
    (
        instr           => instr_id,        -- Instruction input
        ext_data        => ext_data_id,     -- decoded extended data
        srcB_sel        => srcB_sel_id,     -- decoded source B selection for ALU
        srcA_sel        => srcA_sel_id,     -- decoded source A selection for ALU
        shift_sel       => shift_sel_id,    -- for selecting shift input
        res_sel         => res_sel_id(0),   -- for selecting result
        ALU_Code        => ALU_Code_id,     -- decoded ALU code
        shamt           => shamt_id,        -- decoded for shift command's
        ra1             => ra1_id,          -- decoded read address 1 for register file
        rd1             => cmp_d1,          -- read data 1 from register file
        ra2             => ra2_id,          -- decoded read address 2 for register file
        rd2             => cmp_d2,          -- read data 2 from register file
        wa3             => wa3_id,          -- decoded write address 2 for register file
        csr_addr        => csr_addr_id,     -- csr address
        csr_cmd         => csr_cmd_id,      -- csr command
        csr_rreq        => csr_rreq_id(0),  -- read request to csr
        csr_wreq        => csr_wreq_id(0),  -- write request to csr
        csr_sel         => csr_sel_id(0),   -- csr select ( zimm or rd1 )
        m_ret           => m_ret_id,        -- m return
        pc_src          => pc_src,          -- decoded next program counter value enable
        we_rf           => we_rf_id(0),     -- decoded write register file
        we_dm_en        => we_dm_id(0),     -- decoded write data memory
        rf_src          => rf_src_id(0),    -- decoded source register file signal
        size_dm         => size_dm_id,      -- size for load/store instructions
        sign_dm         => sign_dm_id(0),   -- sign extended data memory for load instructions
        branch_src      => branch_src(0),   -- for selecting branch source (JALR)
        branch_type     => branch_type      -- branch type
    );
    -- creating instruction execution unit
    nf_i_exu_0 : nf_i_exu 
    port map
    (
        rd1             => rd1_i_exu,       -- read data from reg file (port1)
        rd2             => rd2_i_exu,       -- read data from reg file (port2)
        ext_data        => ext_data_iexe,   -- sign extended immediate data
        pc_v            => pc_iexe,         -- program-counter value
        srcA_sel        => srcA_sel_iexe,   -- source A enable signal for ALU
        srcB_sel        => srcB_sel_iexe,   -- source B enable signal for ALU
        shift_sel       => shift_sel_iexe,  -- for selecting shift input
        shamt           => shamt_iexe,      -- for shift operations
        ALU_Code        => ALU_Code_iexe,   -- code for ALU
        result          => result_iexe      -- result of ALU operation
    );
    -- creating one load/store unit
    -- creating one load store unit
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
        sign_dm_imem    => sign_dm_imem(0), -- sign for data memory
        size_dm_imem    => size_dm_imem,    -- size data memory from imem stage
        rd_dm_iwb       => rd_dm_iwb,       -- read data for write back stage
        lsu_busy        => lsu_busy(0),     -- load store unit busy
        lsu_err         => lsu_err,         -- load store error
        s_misaligned    => s_misaligned,    -- store misaligned
        l_misaligned    => l_misaligned,    -- load misaligned
        stall_if        => stall_if,        -- stall instruction fetch
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
        wa3_imem        => wa3_imem,        -- write address form memory stage
        we_rf_iexe      => we_rf_iexe(0),   -- write enable register from memory stage
        rf_src_iexe     => rf_src_iexe(0),  -- register source from execution stage
        ra1_id          => ra1_id,          -- read address 1 from decode stage
        ra2_id          => ra2_id,          -- read address 2 from decode stage
        branch_type     => branch_type,     -- branch type
        we_dm_imem      => we_dm_imem(0),   -- write enable data memory from memory stage
        req_ack_dm      => req_ack_dm,      -- request acknowledge data memory
        req_ack_i       => req_ack_i,       -- request acknowledge instruction
        rf_src_imem     => rf_src_imem(0),  -- register source from memory stage
        lsu_busy        => lsu_busy(0),     -- load store unit busy
        lsu_err         => lsu_err,         -- load store unit error
        -- control wires
        stall_if        => stall_if,        -- stall fetch stage
        stall_id        => stall_id,        -- stall decode stage
        stall_iexe      => stall_iexe,      -- stall execution stage
        stall_imem      => stall_imem,      -- stall memory stage
        stall_iwb       => stall_iwb,       -- stall write back stage
        flush_id        => flush_id,        -- flush decode stage
        flush_iexe      => flush_iexe,      -- flush execution stage
        flush_imem      => flush_imem,      -- flush memory stage
        flush_iwb       => flush_iwb        -- flush write back stage
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
    -- creating one nf_csr unit
    nf_csr_0 : nf_csr
    port map
    (
        -- clock and reset
        clk             => clk,             -- clk  
        resetn          => resetn,          -- resetn
        -- csr interface
        csr_addr        => csr_addr,        -- csr address
        csr_rd          => csr_rd,          -- csr read data
        csr_wd          => csr_wd,          -- csr write data
        csr_cmd         => csr_cmd,         -- csr command
        csr_wreq        => csr_wreq,        -- csr write request
        csr_rreq        => csr_rreq,        -- csr read request
        -- scan and control wires
        mtvec_v         => mtvec_v,         -- machine trap-handler base address
        m_ret_pc        => m_ret_pc,        -- m return pc value
        addr_mis        => addr_i_i,        -- address misaligned value
        addr_misalign   => addr_misalign,   -- address misaligned signal
        s_misaligned    => s_misaligned,    -- store misaligned signal
        l_misaligned    => l_misaligned,    -- load misaligned signal
        ls_mis          => result_imem,     -- load slore misaligned value
        m_ret_ls        => pc_imem          -- m return pc value for load/store misaligned
    );

end rtl; -- nf_cpu
