--
-- File            :   nf_seven_seg_dynamic.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.20
-- Language        :   VHDL
-- Description     :   This is dynamic seven seg converter
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_seven_seg_dynamic is
    port
    (
        clk         : in    std_logic;                      -- clock
        resetn      : in    std_logic;                      -- reset
        hex         : in    std_logic_vector(31 downto 0);  -- hexadecimal value input
        cc_ca       : in    std_logic;                      -- common cathode or common anode
        seven_seg   : out   std_logic_vector(7  downto 0);  -- seven segments output
        dig         : out   std_logic_vector(3  downto 0)   -- digital tube selector
    );
end nf_seven_seg_dynamic;

architecture rtl of nf_seven_seg_dynamic is
    signal counter      :   std_logic_vector(17 downto 0);
    signal digit_enable :   std_logic_vector(1  downto 0);
    signal hex_h        :   std_logic_vector(3  downto 0);
    -- nf_seven_seg
    component nf_seven_seg
        port
        (
            hex         : in    std_logic_vector(3 downto 0);   -- hexadecimal value input
            cc_ca       : in    std_logic;                      -- common cathode or common anode
            seven_seg   : out   std_logic_vector(7 downto 0)    -- seven segments output
        );
    end component;
begin

    dig_enable_proc : process(all)
    begin
        dig <= (others => '0');
        case( digit_enable ) is
            when "00"   => dig <= X"E";
            when "01"   => dig <= X"D";
            when "10"   => dig <= X"B";
            when "11"   => dig <= X"7";
        end case;
    end process;

    counter_proc : process(all)
    begin
        if( not resetn ) then
            counter <= (others => '0');
        elsif( rising_edge(clk) ) then
            counter <= counter + '1';
            if( counter(17) ) then
                counter <= (others => '0');
            end if;
        end if;
    end process;

    digit_enable_proc : process(all)
    begin
        if( not resetn ) then
            digit_enable <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( counter(17) ) then
                digit_enable <= digit_enable + '1';
            end if;
        end if;
    end process;

    hex_enable : process(all)
    begin
        hex_h <= hex(3  downto  0);
        case( digit_enable ) is
            when "00"   => hex_h <= hex(3  downto  0);
            when "01"   => hex_h <= hex(7  downto  4);
            when "10"   => hex_h <= hex(11 downto  8);
            when "11"   => hex_h <= hex(15 downto 12);
        end case;
    end process;

    nf_seven_seg_0 : nf_seven_seg 
    port map
    (
        hex         =>  hex_h,      -- hexadecimal value input
        cc_ca       =>  cc_ca,      -- common cathode or common anode
        seven_seg   =>  seven_seg   -- seven segments output
    );

end rtl; -- nf_seven_seg_dynamic
