--
-- File            :   nf_top.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is top unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library nf;
use nf.nf_settings.all;
use nf.nf_program.all;
use nf.nf_mem_pkg.all;

entity nf_top is
    port 
    (
        -- clock and reset
        clk         : in    std_logic;                                  -- clock
        resetn      : in    std_logic;                                  -- reset
        div         : in    std_logic_vector(25 downto 0);              -- clock divide input
        -- pwm side
        pwm         : out   std_logic;                                  -- PWM output
        -- gpio side
        gpi         : in    std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO input
        gpo         : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO output
        gpd         : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO direction
        -- for debug
        reg_addr    : in    std_logic_vector(4  downto 0);              -- scan register address
        reg_data    : out   std_logic_vector(31 downto 0)               -- scan register data
    );
end nf_top;

architecture rtl of nf_top is
    constant Slave_n    :   integer := SLAVE_NUMBER;
    -- instruction memory
    signal instr_addr   :   std_logic_vector(31 downto 0);  -- instruction address
    signal instr_addr_i :   std_logic_vector(31 downto 0);  -- instruction address internal
    signal instr        :   std_logic_vector(31 downto 0);  -- instruction data
    -- cpu special signal
    signal cpu_en       :   std_logic;                      -- cpu enable ( "dividing" clock )
    -- data memory and others's
    signal addr_dm      :   std_logic_vector(31 downto 0);  -- address data memory
    signal we_dm        :   std_logic;                      -- write enable data memory
    signal wd_dm        :   std_logic_vector(31 downto 0);  -- write data for data memory
    signal rd_dm        :   std_logic_vector(31 downto 0);  -- read data from data memory
    -- slave's side
    signal clk_s        :   std_logic;                                      -- clock slave
    signal resetn_s     :   std_logic;                                      -- reset slave
    signal addr_dm_s    :   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- address data memory slave
    signal we_dm_s      :   logic_array  (Slave_n-1 downto 0);              -- write enable data memory slave
    signal wd_dm_s      :   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- write data for data memory slave
    signal rd_dm_s      :   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- read data from data memory slave
    signal addr_dm_s_i  :   std_logic_vector(31 downto 0);                  -- address data memory slave internal
    -- component definition
    -- nf_cpu
    component nf_cpu
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
    end component;
    -- nf_instr_mem
    component nf_instr_mem
        generic
        (
            addr_w  : integer := ADDR_I_W;                  -- actual address memory width
            depth   : integer := MEM_I_DEPTH;               -- depth of memory array
            init    : boolean := False;                     -- init memory?
            i_mem   : mem_t                                 -- init memory
        );
        port 
        (
            addr    : in    std_logic_vector(31 downto 0);  -- instruction address
            instr   : out   std_logic_vector(31 downto 0)   -- instruction data
        );
    end component;
    -- nf_clock_div
    component nf_clock_div
        port 
        (
            -- clock and reset
            clk     : in    std_logic;                      -- clock
            resetn  : in    std_logic;                      -- reset
            -- strobbing
            div     : in    std_logic_vector(25 downto 0);  -- div_number
            en      : out   std_logic                       -- enable strobe
        );
    end component;
    -- nf_pwm
    component nf_pwm
        generic
        (
            pwm_width   : integer := 8                                  -- width pwm register
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
    end component;
    -- nf_gpio
    component nf_gpio
        generic
        (
            gpio_w  : integer := NF_GPIO_WIDTH                      -- width gpio port
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
    end component;
    -- nf_ram
    component nf_ram
    generic
        (
            addr_w  : integer := 6;                         -- actual address memory width
            depth   : integer := 2 ** 6                     -- depth of memory array
        );
        port 
        (
            -- clock and reset
            clk     : in    std_logic;                      -- clock
            -- nf_router side
            addr    : in    std_logic_vector(31 downto 0);  -- address
            we      : in    std_logic;                      -- write enable
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            rd      : out   std_logic_vector(31 downto 0)   -- read data
        );
    end component;
    -- nf_router
    component nf_router
        generic
        (
            Slave_n : integer := SLAVE_NUMBER
        );
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                                      -- clock
            resetn      : in    std_logic;                                      -- reset
            -- cpu side (master)
            addr_dm_m   : in    std_logic_vector(31 downto 0);                  -- master address
            we_dm_m     : in    std_logic;                                      -- master write enable
            wd_dm_m     : in    std_logic_vector(31 downto 0);                  -- master write data
            rd_dm_m     : out   std_logic_vector(31 downto 0);                  -- master read data
            -- devices side (slave's)
            clk_s       : out   std_logic;                                      -- slave clock
            resetn_s    : out   std_logic;                                      -- slave reset
            addr_dm_s   : out   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- slave address
            we_dm_s     : out   logic_array  (Slave_n-1 downto 0);              -- slave write enable
            wd_dm_s     : out   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- slave write data
            rd_dm_s     : in    logic_v_array(Slave_n-1 downto 0)(31 downto 0)  -- slave read data
        );
    end component;
begin

    instr_addr_i <= "00" & instr_addr(31 downto 2);
    addr_dm_s_i  <= "00" & addr_dm_s(0)(31 downto 2);

    -- for future
    rd_dm_s(3) <= 32X"00000000";

    -- creating one register file
    nf_cpu_0: nf_cpu 
    port map    
    (
        clk         => clk,             -- clock
        resetn      => resetn,          -- reset
        instr_addr  => instr_addr,      -- cpu enable signal
        instr       => instr,           -- instruction address
        cpu_en      => cpu_en,          -- instruction data
        addr_dm     => addr_dm,         -- data memory address
        we_dm       => we_dm,           -- data memory write enable
        wd_dm       => wd_dm,           -- data memory write data
        rd_dm       => rd_dm,           -- data memory read data
        reg_addr    => reg_addr,        -- register address
        reg_data    => reg_data         -- register data
    );
    -- creating one instruction memory 
    nf_instr_mem_0: nf_instr_mem 
    generic map
    (
        addr_w      => ADDR_I_W,        -- actual address memory width
        depth       => MEM_I_DEPTH,     -- depth of memory array
        init        => true,
        i_mem       => program
    )
    port map    
    (
        addr        => instr_addr_i,    -- instruction address
        instr       => instr            -- instruction data
    );
    -- creating one strob generating unit for "dividing" clock
    nf_clock_div_0: nf_clock_div 
    port map    
    (
        clk         => clk,             -- clock
        resetn      => resetn,          -- reset
        div         => div,             -- div_number
        en          => cpu_en           -- enable strobe
    );
    -- creating one nf_router_0 unit 
    nf_router_0 : nf_router
    generic map
    (
        Slave_n     => SLAVE_NUMBER
    )
    port map
    (
        -- clock and reset
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        -- cpu side
        addr_dm_m   => addr_dm,     -- master address
        we_dm_m     => we_dm,       -- master write enable
        wd_dm_m     => wd_dm,       -- master write data
        rd_dm_m     => rd_dm,       -- master read data
        -- devices side
        clk_s       => clk_s,       -- slave clock
        resetn_s    => resetn_s,    -- slave reset
        addr_dm_s   => addr_dm_s,   -- slave address
        we_dm_s     => we_dm_s,     -- slave write enable
        wd_dm_s     => wd_dm_s,     -- slave write data
        rd_dm_s     => rd_dm_s      -- slave read data
    );
    -- creating one nf_ram_0 unit
    nf_ram_0 : nf_ram
    generic map
    (
        addr_w  => ADDR_D_W,
        depth   => MEM_D_DEPTH
    )
    port map
    (
        clk     => clk_s,           -- clock
        addr    => addr_dm_s_i,     -- address
        we      => we_dm_s(0),      -- write enable
        wd      => wd_dm_s(0),      -- write data
        rd      => rd_dm_s(0)       -- read data
    );
    -- creating one nf_gpio_0 unit 
    nf_gpio_0 : nf_gpio
    generic map
    (
        gpio_w      => NF_GPIO_WIDTH    -- width gpio port
    )
    port map
    (
        -- clock and reset
        clk         => clk_s,           -- clock
        resetn      => resetn_s,        -- reset
        -- nf_router side
        addr        => addr_dm_s(1),    -- address
        we          => we_dm_s(1),      -- write enable
        wd          => wd_dm_s(1),      -- write data
        rd          => rd_dm_s(1),      -- read data
        -- gpio_side
        gpi         => gpi,             -- GPIO input
        gpo         => gpo,             -- GPIO output
        gpd         => gpd              -- GPIO direction
    );
    -- creating one nf_pwm_0 unit
    nf_pwm_0 : nf_pwm
    generic map
    (
        pwm_width       => 8                -- width pwm register
    )
    port map
    (
        -- clock and reset
        clk             => clk_s,           -- clock
        resetn          => resetn_s,        -- reset
        -- nf_router side
        addr            => addr_dm_s(2),    -- address
        we              => we_dm_s(2),      -- write enable
        wd              => wd_dm_s(2),      -- write data
        rd              => rd_dm_s(2),      -- read data
        -- pmw_side
        pwm_clk         => clk_s,           -- PWM clock input
        pwm_resetn      => resetn_s,        -- PWM reset input
        pwm             => pwm              -- PWM output signal
    );

end rtl; -- nf_top
