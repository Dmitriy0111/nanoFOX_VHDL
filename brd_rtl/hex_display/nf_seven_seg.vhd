--
-- File            :   nf_seven_seg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.20
-- Language        :   VHDL
-- Description     :   This is seven seg converter
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_seven_seg is
    port
    (
        hex         : in    std_logic_vector(3 downto 0);   -- hexadecimal value input
        cc_ca       : in    std_logic;                      -- common cathode or common anode
        seven_seg   : out   std_logic_vector(7 downto 0)    -- seven segments output
    );
end nf_seven_seg;

architecture rtl of nf_seven_seg is
    signal sev_seg : std_logic_vector(7 downto 0);
begin

    seven_seg <= not sev_seg when cc_ca else sev_seg;

    seven_seg_process : process(all)
    begin
        sev_seg <= (others => '0');
        case( hex ) is              -- dp    a     b     c     d     e     f     g
            when X"0"   => sev_seg <= '1' & '1' & '0' & '0' & '0' & '0' & '0' & '0';
            when X"1"   => sev_seg <= '1' & '1' & '1' & '1' & '1' & '0' & '0' & '1';
            when X"2"   => sev_seg <= '1' & '0' & '1' & '0' & '0' & '1' & '0' & '0';
            when X"3"   => sev_seg <= '1' & '0' & '1' & '1' & '0' & '0' & '0' & '0';
            when X"4"   => sev_seg <= '1' & '0' & '0' & '1' & '1' & '0' & '0' & '1';
            when X"5"   => sev_seg <= '1' & '0' & '0' & '1' & '0' & '0' & '1' & '0';
            when X"6"   => sev_seg <= '1' & '0' & '0' & '0' & '0' & '0' & '1' & '0';
            when X"7"   => sev_seg <= '1' & '1' & '1' & '1' & '1' & '0' & '0' & '0';
            when X"8"   => sev_seg <= '1' & '0' & '0' & '0' & '0' & '0' & '0' & '0';
            when X"9"   => sev_seg <= '1' & '0' & '0' & '1' & '1' & '0' & '0' & '0';
            when X"A"   => sev_seg <= '1' & '0' & '0' & '0' & '1' & '0' & '0' & '0';
            when X"B"   => sev_seg <= '1' & '0' & '0' & '0' & '0' & '0' & '1' & '1';
            when X"C"   => sev_seg <= '1' & '1' & '0' & '0' & '0' & '1' & '1' & '0';
            when X"D"   => sev_seg <= '1' & '0' & '1' & '0' & '0' & '0' & '0' & '1';
            when X"E"   => sev_seg <= '1' & '0' & '0' & '0' & '0' & '1' & '1' & '0';
            when X"F"   => sev_seg <= '1' & '0' & '0' & '0' & '1' & '1' & '1' & '0';
            when others => sev_seg <= ( others => '0' );
        end case;
    end process;

end rtl; -- nf_seven_seg
