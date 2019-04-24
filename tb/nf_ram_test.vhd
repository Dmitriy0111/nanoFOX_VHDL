library ieee;
use ieee.std_logic_1164.all;

entity nf_ram_test is
end nf_ram_test;

architecture testbench of nf_ram_test is
    component nf_ram
        generic
        (
            addr_w  : integer := 6;                         -- actual address memory width
            depth   : integer := 2 ** 6                     -- depth of memory array
        );
        port 
        (
            clk     : in    std_logic;                      -- clock
            addr    : in    std_logic_vector(31 downto 0);  -- address
            we      : in    std_logic_vector(3  downto 0);  -- write enable
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            rd      : out   std_logic_vector(31 downto 0)   -- read data
        );
    end component;
    signal  clk     : std_logic;                      -- clock
    signal  addr    : std_logic_vector(31 downto 0);  -- address
    signal  we      : std_logic_vector(3  downto 0);  -- write enable
    signal  wd      : std_logic_vector(31 downto 0);  -- write data
    signal  rd      : std_logic_vector(31 downto 0);  -- read data
begin

    nf_ram_0 : nf_ram
        generic map
        (
            addr_w  => 6,       -- actual address memory width
            depth   => 2 ** 6   -- depth of memory array
        )
        port map
        (
            clk     => clk,     -- clock
            addr    => addr,    -- address
            we      => we,      -- write enable
            wd      => wd,      -- write data
            rd      => rd       -- read data
        );

        read_proc : process
        begin
            addr <= 32X"0";
            wait for 20 ns;
            addr <= 32X"1";
            wait for 20 ns;
            addr <= 32X"2";
            wait for 20 ns;
            addr <= 32X"3";
            wait for 20 ns;
            addr <= 32X"4";
            wait for 20 ns;
            wait;
        end process;

end testbench;