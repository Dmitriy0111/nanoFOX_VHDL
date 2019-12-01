--
-- File            :   nf_register.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is file with registers modules
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- simple register with reset and clock 
entity nf_register is
    generic
    (
        width   : integer   := 1
    );
    port
    (
        clk     : in    std_logic;                          -- clk
        resetn  : in    std_logic;                          -- resetn
        datai   : in    std_logic_vector(width-1 downto 0); -- input data
        datao   : out   std_logic_vector(width-1 downto 0)  -- output data
    );
end nf_register;

architecture rtl of nf_register is
begin
    reg_proc : process( clk, resetn )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                datao <= (others => '0');
            else
                datao <= datai;
            end if;
        end if;
    end process;
end rtl; -- nf_register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- register with write enable input
entity nf_register_we is
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
end nf_register_we; 

architecture rtl of nf_register_we is
begin
    reg_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                datao <= (others => '0');
            elsif( we ) then
                datao <= datai;
            end if;
        end if;
    end process;
end rtl; -- nf_register_we

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- register with write enable input and not zero reset value
entity nf_register_we_r is
    generic
    (
        width   : integer   := 1;
        rst_val : integer   := 0
    );
    port
    (
        clk     : in    std_logic;                          -- clk
        resetn  : in    std_logic;                          -- resetn
        we      : in    std_logic;                          -- write enable
        datai   : in    std_logic_vector(width-1 downto 0); -- input data
        datao   : out   std_logic_vector(width-1 downto 0)  -- output data
    );
end nf_register_we_r;

architecture rtl of nf_register_we_r is
begin
    reg_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                datao <= std_logic_vector(to_unsigned(rst_val,width));
            elsif( we ) then
                datao <= datai;
            end if;
        end if;
    end process;
end rtl; -- nf_register_we_r

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- register with clr input
entity nf_register_clr is
    generic
    (
        width   : integer   := 1
    );
    port
    (
        clk     : in    std_logic;                          -- clk
        resetn  : in    std_logic;                          -- resetn
        clr     : in    std_logic;                          -- clear register
        datai   : in    std_logic_vector(width-1 downto 0); -- input data
        datao   : out   std_logic_vector(width-1 downto 0)  -- output data
    );
end nf_register_clr; 

architecture rtl of nf_register_clr is
begin
    reg_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                datao <= (others => '0');
            elsif( clr ) then
                datao <= (others => '0');
            else
                datao <= datai;
            end if;
        end if;
    end process;
end rtl; -- nf_register_clr

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- register with clr and we input's
entity nf_register_we_clr is
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
end nf_register_we_clr; 

architecture rtl of nf_register_we_clr is
begin
    reg_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                datao <= (others => '0');
            elsif( we ) then
                if( clr ) then
                    datao <= (others => '0');
                else
                    datao <= datai;
                end if;
            end if;
        end if;
    end process;
end rtl; -- nf_register_we_clr
