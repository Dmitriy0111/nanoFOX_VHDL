--
-- File            :   nf_components.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.24
-- Language        :   VHDL
-- Description     :   This is nf components package
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

library nf;
use nf.nf_settings.all;
use nf.nf_mem_pkg.all;

package nf_components is
    -- nf_alu
    component nf_alu
        port
        (
            srcA        : in    std_logic_vector(31 downto 0);  -- source A for ALU unit
            srcB        : in    std_logic_vector(31 downto 0);  -- source B for ALU unit
            shift       : in    std_logic_vector(4  downto 0);  -- for shift operation
            ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
            result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
        );
    end component nf_alu;
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
    end component nf_branch_unit;
    -- nf_control_unit
    component nf_control_unit
        port
        (
            instr_type  : in   std_logic_vector(1  downto 0);   -- instruction type
            opcode      : in   std_logic_vector(4  downto 0);   -- operation code field in instruction code
            funct3      : in   std_logic_vector(2  downto 0);   -- funct 3 field in instruction code
            funct7      : in   std_logic_vector(6  downto 0);   -- funct 7 field in instruction code
            funct12     : in   std_logic_vector(11 downto 0);   -- funct 12 field in instruction code
            wa3         : in   std_logic_vector(4  downto 0);   -- write address field
            imm_src     : out  std_logic_vector(4  downto 0);   -- for enable immediate data
            srcB_sel    : out  std_logic_vector(1  downto 0);   -- for selecting srcB ALU
            srcA_sel    : out  std_logic_vector(1  downto 0);   -- for selecting srcA ALU
            shift_sel   : out  std_logic_vector(1  downto 0);   -- for selecting shift input
            res_sel     : out  std_logic;                       -- for selecting result
            branch_type : out  std_logic_vector(3  downto 0);   -- for executing branch instructions
            branch_hf   : out  std_logic;                       -- branch help field
            branch_src  : out  std_logic;                       -- for selecting branch source (JALR)
            we_rf       : out  std_logic;                       -- write enable signal for register file
            we_dm       : out  std_logic;                       -- write enable signal for data memory and others
            rf_src      : out  std_logic;                       -- write data select for register file
            size_dm     : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
            sign_dm     : out  std_logic;                       -- sign extended data memory for load instructions
            csr_cmd     : out  std_logic_vector(1  downto 0);   -- csr command
            csr_rreq    : out  std_logic;                       -- read request to csr
            csr_wreq    : out  std_logic;                       -- write request to csr
            csr_sel     : out  std_logic;                       -- csr select ( zimm or rd1 )
            m_ret       : out  std_logic;                       -- m return
            ALU_Code    : out  std_logic_vector(3  downto 0)    -- output code for ALU unit
        );
    end component nf_control_unit;
    -- nf_cpu_cc
    component nf_cpu_cc
        port
        (
            -- clock and reset
            clk             : in    std_logic;                      -- clock
            resetn          : in    std_logic;                      -- reset
            -- instruction memory (IF)
            addr_i          : in    std_logic_vector(31 downto 0);  -- address instruction memory
            rd_i            : out   std_logic_vector(31 downto 0);  -- read instruction memory
            wd_i            : in    std_logic_vector(31 downto 0);  -- write instruction memory
            we_i            : in    std_logic;                      -- write enable instruction memory signal
            size_i          : in    std_logic_vector(1  downto 0);  -- size for load/store instructions
            req_i           : in    std_logic;                      -- request instruction memory signal
            req_ack_i       : out   std_logic;                      -- request acknowledge instruction memory signal
            -- data memory and other's
            addr_dm         : in    std_logic_vector(31 downto 0);  -- address data memory
            rd_dm           : out   std_logic_vector(31 downto 0);  -- read data memory
            wd_dm           : in    std_logic_vector(31 downto 0);  -- write data memory
            we_dm           : in    std_logic;                      -- write enable data memory signal
            size_dm         : in    std_logic_vector(1  downto 0);  -- size for load/store instructions
            req_dm          : in    std_logic;                      -- request data memory signal
            req_ack_dm      : out   std_logic;                      -- request acknowledge data memory signal
            -- cross connect data
            addr_cc         : out   std_logic_vector(31 downto 0);  -- address cc_data memory
            rd_cc           : in    std_logic_vector(31 downto 0);  -- read cc_data memory
            wd_cc           : out   std_logic_vector(31 downto 0);  -- write cc_data memory
            we_cc           : out   std_logic;                      -- write enable cc_data memory signal
            size_cc         : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
            req_cc          : out   std_logic;                      -- request cc_data memory signal
            req_ack_cc      : in    std_logic                       -- request acknowledge cc_data memory signal
        );
    end component nf_cpu_cc;
    -- nf_cpu
    component nf_cpu
        generic
        (
            ver         : string
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
    end component nf_cpu;
    -- nf_csr
    component nf_csr
        port
        (
            -- clock and reset
            clk             : in   std_logic;                       -- clk  
            resetn          : in   std_logic;                       -- resetn
            -- csr interface
            csr_addr        : in   std_logic_vector(11 downto 0);   -- csr address
            csr_rd          : out  std_logic_vector(31 downto 0);   -- csr read data
            csr_wd          : in   std_logic_vector(31 downto 0);   -- csr write data
            csr_cmd         : in   std_logic_vector(1  downto 0);   -- csr command
            csr_wreq        : in   std_logic;                       -- csr write request
            csr_rreq        : in   std_logic;                       -- csr read request
            -- scan and control wires
            mtvec_v         : out  std_logic_vector(31 downto 0);   -- machine trap-handler base address
            m_ret_pc        : out  std_logic_vector(31 downto 0);   -- m return pc value
            addr_mis        : in   std_logic_vector(31 downto 0);   -- address misaligned value
            addr_misalign   : in   std_logic;                       -- address misaligned signal
            s_misaligned    : in   std_logic;                       -- store misaligned signal
            l_misaligned    : in   std_logic;                       -- load misaligned signal
            ls_mis          : in   std_logic_vector(31 downto 0);   -- load slore misaligned value
            m_ret_ls        : in   std_logic_vector(31 downto 0)    -- m return pc value for load/store misaligned
        );
    end component nf_csr;
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
    end component nf_hz_bypass_unit;
    -- nf_hz_stall_unit
    component nf_hz_stall_unit
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
    end component nf_hz_stall_unit;
    -- nf_i_du
    component nf_i_du
        port
        (
            instr       : in    std_logic_vector(31 downto 0);  -- Instruction input
            ext_data    : out   std_logic_vector(31 downto 0);  -- decoded extended data
            srcB_sel    : out   std_logic_vector(1  downto 0);  -- decoded source B selection for ALU
            srcA_sel    : out   std_logic_vector(1  downto 0);  -- decoded source A selection for ALU
            shift_sel   : out   std_logic_vector(1  downto 0);  -- for selecting shift input
            res_sel     : out   std_logic;                      -- for selecting result
            ALU_Code    : out   std_logic_vector(3  downto 0);  -- decoded ALU code
            shamt       : out   std_logic_vector(4  downto 0);  -- decoded for shift command's
            ra1         : out   std_logic_vector(4  downto 0);  -- decoded read address 1 for register file
            rd1         : in    std_logic_vector(31 downto 0);  -- read data 1 from register file
            ra2         : out   std_logic_vector(4  downto 0);  -- decoded read address 2 for register file
            rd2         : in    std_logic_vector(31 downto 0);  -- read data 2 from register file
            wa3         : out   std_logic_vector(4  downto 0);  -- decoded write address 2 for register file
            csr_addr    : out   std_logic_vector(11 downto 0);  -- csr address
            csr_cmd     : out   std_logic_vector(1  downto 0);  -- csr command
            csr_rreq    : out   std_logic;                      -- read request to csr
            csr_wreq    : out   std_logic;                      -- write request to csr
            csr_sel     : out   std_logic;                      -- csr select ( zimm or rd1 )
            m_ret       : out   std_logic;                      -- m return
            pc_src      : out   std_logic;                      -- decoded next program counter value enable
            we_rf       : out   std_logic;                      -- decoded write register file
            we_dm_en    : out   std_logic;                      -- decoded write data memory
            rf_src      : out   std_logic;                      -- decoded source register file signal
            size_dm     : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
            sign_dm     : out   std_logic;                      -- sign extended data memory for load instructions
            branch_src  : out   std_logic;                      -- for selecting branch source (JALR)
            branch_type : out   std_logic_vector(3  downto 0)   -- branch type
        );
    end component nf_i_du;
    -- nf_i_exu
    component nf_i_exu
        port
        (
            rd1         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port1)
            rd2         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port2)
            ext_data    : in    std_logic_vector(31 downto 0);  -- sign extended immediate data
            pc_v        : in    std_logic_vector(31 downto 0);  -- program-counter value
            srcA_sel    : in    std_logic_vector(1  downto 0);  -- source A enable signal for ALU
            srcB_sel    : in    std_logic_vector(1  downto 0);  -- source B enable signal for ALU
            shift_sel   : in    std_logic_vector(1  downto 0);  -- for selecting shift input
            shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
            ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
            result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
        );
    end component nf_i_exu;
    -- nf_i_fu
    component nf_i_fu
        port
        (
            -- clock and reset
            clk             : in   std_logic;                       -- clock
            resetn          : in   std_logic;                       -- reset
            -- program counter inputs   
            pc_branch       : in   std_logic_vector(31 downto 0);   -- program counter branch value from decode stage
            pc_src          : in   std_logic;                       -- next program counter source
            stall_if        : in   std_logic;                       -- stalling instruction fetch stage
            instr_if        : out  std_logic_vector(31 downto 0);   -- instruction fetch
            last_pc         : out  std_logic_vector(31 downto 0);   -- last program_counter
            mtvec_v         : in   std_logic_vector(31 downto 0);   -- machine trap-handler base address
            m_ret           : in   std_logic;                       -- m return
            m_ret_pc        : in   std_logic_vector(31 downto 0);   -- m return pc value
            addr_misalign   : out  std_logic;                       -- address misaligned
            lsu_err         : in   std_logic;                       -- load store unit error
            -- memory inputs/outputs
            addr_i          : out  std_logic_vector(31 downto 0);   -- address instruction memory
            rd_i            : in   std_logic_vector(31 downto 0);   -- read instruction memory
            wd_i            : out  std_logic_vector(31 downto 0);   -- write instruction memory
            we_i            : out  std_logic;                       -- write enable instruction memory signal
            size_i          : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
            req_i           : out  std_logic;                       -- request instruction memory signal
            req_ack_i       : in   std_logic                        -- request acknowledge instruction memory signal
        );
    end component nf_i_fu;
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
            sign_dm_imem    : in    std_logic;                      -- sign for load operations
            size_dm_imem    : in    std_logic_vector(1  downto 0);  -- size data memory from imem stage
            rd_dm_iwb       : out   std_logic_vector(31 downto 0);  -- read data for write back stage
            lsu_busy        : out   std_logic;                      -- load store unit busy
            lsu_err         : out   std_logic;                      -- load store error
            s_misaligned    : out   std_logic;                      -- store misaligned
            l_misaligned    : out   std_logic;                      -- load misaligned
            stall_if        : in    std_logic;                      -- stall instruction fetch
            -- data memory and other's
            addr_dm         : out   std_logic_vector(31 downto 0);  -- address data memory
            rd_dm           : in    std_logic_vector(31 downto 0);  -- read data memory
            wd_dm           : out   std_logic_vector(31 downto 0);  -- write data memory
            we_dm           : out   std_logic;                      -- write enable data memory signal
            size_dm         : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
            req_dm          : out   std_logic;                      -- request data memory signal
            req_ack_dm      : in    std_logic                       -- request acknowledge data memory signal
        );
    end component nf_i_lsu;
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
    end component nf_reg_file;
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
    end component nf_sign_ex;
    -- nf_register
    component nf_register
        generic
        (
            width   : integer
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component nf_register;
    -- nf_register_we
    component nf_register_we
        generic
        (
            width   : integer
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component nf_register_we; 
    -- nf_register_we_r
    component nf_register_we_r
        generic
        (
            width   : integer;
            rst_val : integer
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component nf_register_we_r;
    -- nf_register_clr
    component nf_register_clr
        generic
        (
            width   : integer
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            clr     : in    std_logic;                          -- clear register
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component nf_register_clr; 
    -- nf_register_we_clr
    component nf_register_we_clr
        generic
        (
            width   : integer
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
    end component nf_register_we_clr;
    -- nf_ahb_dec
    component nf_ahb_dec
        generic
        (
            slave_c : integer
        );
        port
        (
            haddr   : in    std_logic_vector(31        downto 0);   -- AHB address 
            hsel    : out   std_logic_vector(slave_c-1 downto 0)    -- hsel signal
        );
    end component nf_ahb_dec;
    -- nf_ahb_gpio
    component nf_ahb_gpio
        generic
        (
            gpio_w      : integer
        );
        port
        (
            -- clock and reset
            hclk        : in    std_logic;                              -- hclock
            hresetn     : in    std_logic;                              -- hresetn
            -- AHB GPIO slave side
            haddr_s     : in    std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HADDR
            hwdata_s    : in    std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HWDATA
            hrdata_s    : out   std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HRDATA
            hwrite_s    : in    std_logic;                              -- AHB - GPIO-slave HWRITE
            htrans_s    : in    std_logic_vector(1        downto 0);    -- AHB - GPIO-slave HTRANS
            hsize_s     : in    std_logic_vector(2        downto 0);    -- AHB - GPIO-slave HSIZE
            hburst_s    : in    std_logic_vector(2        downto 0);    -- AHB - GPIO-slave HBURST
            hresp_s     : out   std_logic_vector(1        downto 0);    -- AHB - GPIO-slave HRESP
            hready_s    : out   std_logic;                              -- AHB - GPIO-slave HREADYOUT
            hsel_s      : in    std_logic;                              -- AHB - GPIO-slave HSEL
            -- GPIO side
            gpi         : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
            gpo         : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
            gpd         : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
        );
    end component nf_ahb_gpio;
    -- nf_ahb_mux
    component nf_ahb_mux is
        generic
        (
            slave_c     : integer
        );
        port
        (
            hsel_ff     : in    std_logic_vector(slave_c-1 downto 0);           -- hsel after flip-flop
            -- slave side
            hrdata_s    : in    logic_v_array(slave_c-1 downto 0)(31 downto 0); -- AHB read data slaves 
            hresp_s     : in    logic_v_array(slave_c-1 downto 0)(1  downto 0); -- AHB response slaves
            hready_s    : in    logic_array  (slave_c-1 downto 0);              -- AHB ready slaves
            -- master side
            hrdata      : out   std_logic_vector(31 downto 0);                  -- AHB read data master 
            hresp       : out   std_logic_vector(1  downto 0);                  -- AHB response master
            hready      : out   std_logic                                       -- AHB ready master
        );
    end component nf_ahb_mux;
    -- nf_ahb_pwm
    component nf_ahb_pwm
        generic
        (
            pwm_width   : integer
        );
        port
        (
            -- clock and reset
            hclk        : in    std_logic;                      -- hclk
            hresetn     : in    std_logic;                      -- hresetn
            -- AHB PWM slave side
            haddr_s     : in    std_logic_vector(31 downto 0);  -- AHB - PWM-slave HADDR
            hwdata_s    : in    std_logic_vector(31 downto 0);  -- AHB - PWM-slave HWDATA
            hrdata_s    : out   std_logic_vector(31 downto 0);  -- AHB - PWM-slave HRDATA
            hwrite_s    : in    std_logic;                      -- AHB - PWM-slave HWRITE
            htrans_s    : in    std_logic_vector(1  downto 0);  -- AHB - PWM-slave HTRANS
            hsize_s     : in    std_logic_vector(2  downto 0);  -- AHB - PWM-slave HSIZE
            hburst_s    : in    std_logic_vector(2  downto 0);  -- AHB - PWM-slave HBURST
            hresp_s     : out   std_logic_vector(1  downto 0);  -- AHB - PWM-slave HRESP
            hready_s    : out   std_logic;                      -- AHB - PWM-slave HREADYOUT
            hsel_s      : in    std_logic;                      -- AHB - PWM-slave HSEL
            -- PWM side
            pwm_clk     : in    std_logic;                      -- PWM_clk
            pwm_resetn  : in    std_logic;                      -- PWM_resetn
            pwm         : out   std_logic                       -- PWM output signal
        );
    end component nf_ahb_pwm;
    -- nf_ahb_ram
    component nf_ahb_ram
        port
        (
            -- clock and reset
            hclk        : in    std_logic;                      -- hclk
            hresetn     : in    std_logic;                      -- hresetn
            -- AHB RAM slave side
            haddr_s     : in    std_logic_vector(31 downto 0);  -- AHB - RAM-slave HADDR
            hwdata_s    : in    std_logic_vector(31 downto 0);  -- AHB - RAM-slave HWDATA
            hrdata_s    : out   std_logic_vector(31 downto 0);  -- AHB - RAM-slave HRDATA
            hwrite_s    : in    std_logic;                      -- AHB - RAM-slave HWRITE
            htrans_s    : in    std_logic_vector(1  downto 0);  -- AHB - RAM-slave HTRANS
            hsize_s     : in    std_logic_vector(2  downto 0);  -- AHB - RAM-slave HSIZE
            hburst_s    : in    std_logic_vector(2  downto 0);  -- AHB - RAM-slave HBURST
            hresp_s     : out   std_logic_vector(1  downto 0);  -- AHB - RAM-slave HRESP
            hready_s    : out   std_logic;                      -- AHB - RAM-slave HREADYOUT
            hsel_s      : in    std_logic;                      -- AHB - RAM-slave HSEL
            -- RAM side
            ram_addr    : out   std_logic_vector(31 downto 0);  -- addr memory
            ram_wd      : out   std_logic_vector(31 downto 0);  -- write data
            ram_rd      : in    std_logic_vector(31 downto 0);  -- read data
            ram_we      : out   std_logic_vector(3  downto 0)   -- write enable
        );
    end component nf_ahb_ram;
    -- nf_ahb_router
    component nf_ahb_router
        generic
        (
            slave_c : integer
        );
        port
        (
            hclk        : in   std_logic;                                       -- hclk
            hresetn     : in   std_logic;                                       -- hresetn
            -- Master side
            haddr       : in   std_logic_vector(31 downto 0);                   -- AHB - Master HADDR
            hwdata      : in   std_logic_vector(31 downto 0);                   -- AHB - Master HWDATA
            hrdata      : out  std_logic_vector(31 downto 0);                   -- AHB - Master HRDATA
            hwrite      : in   std_logic;                                       -- AHB - Master HWRITE
            htrans      : in   std_logic_vector(1  downto 0);                   -- AHB - Master HTRANS
            hsize       : in   std_logic_vector(2  downto 0);                   -- AHB - Master HSIZE
            hburst      : in   std_logic_vector(2  downto 0);                   -- AHB - Master HBURST
            hresp       : out  std_logic_vector(1  downto 0);                   -- AHB - Master HRESP
            hready      : out  std_logic;                                       -- AHB - Master HREADY
            -- Slaves side
            haddr_s     : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HADDR
            hwdata_s    : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HWDATA
            hrdata_s    : in   logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HRDATA
            hwrite_s    : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HWRITE
            htrans_s    : out  logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HTRANS
            hsize_s     : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HSIZE
            hburst_s    : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HBURST
            hresp_s     : in   logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HRESP
            hready_s    : in   logic_array  (slave_c-1 downto 0);               -- AHB - Slave HREADY
            hsel_s      : out  logic_array  (slave_c-1 downto 0)                -- AHB - Slave HSEL
        );
    end component nf_ahb_router;
    -- nf_ahb_top
    component nf_ahb_top
        generic
        (
            slave_c     : integer
        );
        port
        (
            clk         : in   std_logic;                                       -- clk
            resetn      : in   std_logic;                                       -- resetn
            -- AHB slaves side
            haddr_s     : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HADDR 
            hwdata_s    : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HWDATA 
            hrdata_s    : in   logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HRDATA 
            hwrite_s    : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HWRITE 
            htrans_s    : out  logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HTRANS 
            hsize_s     : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HSIZE 
            hburst_s    : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HBURST 
            hresp_s     : in   logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HRESP 
            hready_s    : in   logic_array  (slave_c-1 downto 0);               -- AHB - Slave HREADYOUT 
            hsel_s      : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HSEL
            -- core side
            addr        : in   std_logic_vector(31 downto 0);                   -- address memory
            rd          : out  std_logic_vector(31 downto 0);                   -- read memory
            wd          : in   std_logic_vector(31 downto 0);                   -- write memory
            we          : in   std_logic;                                       -- write enable signal
            size        : in   std_logic_vector(1  downto 0);                   -- size for load/store instructions
            req         : in   std_logic;                                       -- request memory signal
            req_ack     : out  std_logic                                        -- request acknowledge memory signal
        );
    end component nf_ahb_top;
    -- nf_ahb_uart
    component nf_ahb_uart
        port
        (
            -- clock and reset
            hclk        : in   std_logic;                       -- hclock
            hresetn     : in   std_logic;                       -- hresetn
            -- AHB UART slave side
            haddr_s     : in   std_logic_vector(31 downto 0);   -- AHB - UART-slave HADDR
            hwdata_s    : in   std_logic_vector(31 downto 0);   -- AHB - UART-slave HWDATA
            hrdata_s    : out  std_logic_vector(31 downto 0);   -- AHB - UART-slave HRDATA
            hwrite_s    : in   std_logic;                       -- AHB - UART-slave HWRITE
            htrans_s    : in   std_logic_vector(1  downto 0);   -- AHB - UART-slave HTRANS
            hsize_s     : in   std_logic_vector(2  downto 0);   -- AHB - UART-slave HSIZE
            hburst_s    : in   std_logic_vector(2  downto 0);   -- AHB - UART-slave HBURST
            hresp_s     : out  std_logic_vector(1  downto 0);   -- AHB - UART-slave HRESP
            hready_s    : out  std_logic;                       -- AHB - UART-slave HREADYOUT
            hsel_s      : in   std_logic;                       -- AHB - UART-slave HSEL
            -- UART side
            uart_tx     : out  std_logic;                       -- UART tx wire
            uart_rx     : in   std_logic                        -- UART rx wire
        );
    end component nf_ahb_uart;
    -- nf_ahb2core
    component nf_ahb2core
        port
        (
            clk     : in   std_logic;                       -- clk
            resetn  : in   std_logic;                       -- resetn
            -- AHB side
            haddr   : out  std_logic_vector(31 downto 0);   -- AHB HADDR
            hwdata  : out  std_logic_vector(31 downto 0);   -- AHB HWDATA
            hrdata  : in   std_logic_vector(31 downto 0);   -- AHB HRDATA
            hwrite  : out  std_logic;                       -- AHB HWRITE
            htrans  : out  std_logic_vector(1  downto 0);   -- AHB HTRANS
            hsize   : out  std_logic_vector(2  downto 0);   -- AHB HSIZE
            hburst  : out  std_logic_vector(2  downto 0);   -- AHB HBURST
            hresp   : in   std_logic_vector(1  downto 0);   -- AHB HRESP
            hready  : in   std_logic;                       -- AHB HREADY
            -- core side
            addr    : in   std_logic_vector(31 downto 0);   -- address memory
            wd      : in   std_logic_vector(31 downto 0);   -- write memory
            rd      : out  std_logic_vector(31 downto 0);   -- read memory
            we      : in   std_logic;                       -- write enable signal
            size    : in   std_logic_vector(1  downto 0);   -- size for load/store instructions
            req     : in   std_logic;                       -- request memory signal
            req_ack : out  std_logic                        -- request acknowledge memory signal
        );
    end component nf_ahb2core;
    -- nf_ram
    component nf_ram
        generic
        (
            addr_w  : integer;                              -- actual address memory width
            depth   : integer;                              -- depth of memory array
            init    : boolean;                              -- init memory?
            i_mem   : mem_t                                 -- init memory
        );
        port
        (
            clk     : in    std_logic;                      -- clock
            addr    : in    std_logic_vector(31 downto 0);  -- address
            we      : in    std_logic_vector(3  downto 0);  -- write enable
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            rd      : out   std_logic_vector(31 downto 0)   -- read data
        );
    end component nf_ram;
    -- nf_param_mem
    component nf_param_mem
        generic
        (
            addr_w  : integer;                                      -- actual address memory width
            data_w  : integer;                                      -- actual data width
            depth   : integer                                       -- depth of memory array
        );
        port
        (
            clk     : in    std_logic;                              -- clock
            waddr   : in    std_logic_vector(addr_w-1 downto 0);    -- write address
            raddr   : in    std_logic_vector(addr_w-1 downto 0);    -- read address
            we      : in    std_logic;                              -- write enable
            wd      : in    std_logic_vector(data_w-1 downto 0);    -- write data
            rd      : out   std_logic_vector(data_w-1 downto 0)     -- read data
        );
    end component nf_param_mem;
    -- nf_cdc
    component nf_cdc
        port
        (
            resetn_1    : in   std_logic;   -- first reset
            resetn_2    : in   std_logic;   -- second reset
            clk_1       : in   std_logic;   -- first clock
            clk_2       : in   std_logic;   -- second clock
            we_1        : in   std_logic;   -- first write enable
            we_2        : in   std_logic;   -- second write enable
            data_1_in   : in   std_logic;   -- first data input
            data_2_in   : in   std_logic;   -- second data input
            data_1_out  : out  std_logic;   -- first data output
            data_2_out  : out  std_logic;   -- second data output
            wait_1      : out  std_logic;   -- first wait
            wait_2      : out  std_logic    -- second wait
        );
    end component nf_cdc;
    -- nf_uart_transmitter
    component nf_uart_transmitter
        port
        (
            -- reset and clock
            clk     : in    std_logic;                      -- clk
            resetn  : in    std_logic;                      -- resetn
            -- controller side interface
            tr_en   : in    std_logic;                      -- transmitter enable
            comp    : in    std_logic_vector(15 downto 0);  -- compare input for setting baudrate
            tx_data : in    std_logic_vector(7  downto 0);  -- data for transfer
            req     : in    std_logic;                      -- request signal
            req_ack : out   std_logic;                      -- acknowledgent signal
            -- uart tx side
            uart_tx : out   std_logic                       -- UART tx wire
        );
    end component nf_uart_transmitter;
    -- nf_uart_receiver
    component nf_uart_receiver
        port
        (
            -- reset and clock
            clk         : in    std_logic;                      -- clk
            resetn      : in    std_logic;                      -- resetn
            -- controller side interface
            rec_en      : in    std_logic;                      -- receiver enable
            comp        : in    std_logic_vector(15 downto 0);  -- compare input for setting baudrate
            rx_data     : out   std_logic_vector(7  downto 0);  -- received data
            rx_valid    : out   std_logic;                      -- receiver data valid
            rx_val_set  : in    std_logic;                      -- receiver data valid set
            -- uart rx side
            uart_rx     : in    std_logic                       -- UART rx wire
        );
    end component nf_uart_receiver;
    -- nf_uart_top
    component nf_uart_top
        port
        (
            -- reset and clock
            clk     : in    std_logic;                      -- clk
            resetn  : in    std_logic;                      -- resetn
            -- bus side
            addr    : in    std_logic_vector(31 downto 0);  -- address
            we      : in    std_logic;                      -- write enable
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            rd      : out   std_logic_vector(31 downto 0);  -- read data
            -- uart side
            uart_tx : out   std_logic;                      -- UART tx wire
            uart_rx : in    std_logic                       -- UART rx wire
        );
    end component nf_uart_top;
    -- nf_pwm
    component nf_pwm
        generic
        (
            pwm_width   : integer                                       -- width pwm register
        );
        port
        (
            -- clock and reset
            clk         : in    std_logic;                              -- clock
            resetn      : in    std_logic;                              -- reset
            -- nf_router side
            addr        : in    std_logic_vector(31       downto 0);    -- address
            we          : in    std_logic;                              -- write enable
            wd          : in    std_logic_vector(31       downto 0);    -- write data
            rd          : out   std_logic_vector(31       downto 0);    -- read data
            -- pmw_side
            pwm_clk     : in    std_logic;                              -- PWM clock input
            pwm_resetn  : in    std_logic;                              -- PWM reset input
            pwm         : out   std_logic                               -- PWM output signal
        );
    end component nf_pwm;
    -- nf_gpio
    component nf_gpio
        generic
        (
            gpio_w  : integer                                       -- width gpio port
        );
        port
        (
            -- clock and reset
            clk     : in    std_logic;                              -- clock
            resetn  : in    std_logic;                              -- reset
            -- nf_router side
            addr    : in    std_logic_vector(31       downto 0);    -- address
            we      : in    std_logic;                              -- write enable
            wd      : in    std_logic_vector(31       downto 0);    -- write data
            rd      : out   std_logic_vector(31       downto 0);    -- read data
            -- gpio_side
            gpi     : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
            gpo     : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
            gpd     : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
        );
    end component nf_gpio;
    -- nf_cache
    component nf_cache
        generic
        (
            addr_w  : integer := 6;                                 -- actual address memory width
            depth   : integer := 2 ** 6;                            -- depth of memory array
            tag_w   : integer := 6                                  -- tag width
        );
        port
        (
            clk     : in    std_logic;                              -- clock
            raddr   : in    std_logic_vector(31      downto 0);     -- read address
            waddr   : in    std_logic_vector(31      downto 0);     -- write address
            we_cb   : in    std_logic_vector(3       downto 0);     -- write cache enable
            we_ctv  : in    std_logic;                              -- write tag valid enable
            wd      : in    std_logic_vector(31      downto 0);     -- write data
            vld     : in    std_logic_vector(3       downto 0);     -- write valid
            wtag    : in    std_logic_vector(tag_w-1 downto 0);     -- write tag
            rd      : out   std_logic_vector(31      downto 0);     -- read data
            hit     : out   std_logic_vector(3       downto 0)      -- cache hit
        );
    end component nf_cache;
    -- nf_cache_controller
    component nf_cache_controller
        generic
        (
            addr_w  : integer := 6;                         -- actual address memory width
            depth   : integer := 2 ** 6;                    -- depth of memory array
            tag_w   : integer := 6                          -- tag width
        );
        port
        (
            clk     : in    std_logic;                      -- clock
            raddr   : in    std_logic_vector(31 downto 0);  -- read address
            waddr   : in    std_logic_vector(31 downto 0);  -- write address
            swe     : in    std_logic;                      -- store write enable
            lwe     : in    std_logic;                      -- load write enable
            req_l   : in    std_logic;                      -- requets load
            size_d  : in    std_logic_vector(1  downto 0);  -- data size
            size_r  : in    std_logic_vector(1  downto 0);  -- read data size
            sd      : in    std_logic_vector(31 downto 0);  -- store data
            ld      : in    std_logic_vector(31 downto 0);  -- load data
            rd      : out   std_logic_vector(31 downto 0);  -- read data
            hit     : out   std_logic                       -- cache hit
        );
    end component nf_cache_controller;

end nf_components;

package body nf_components is

end nf_components;
