--
-- File            :   nf_seven_seg_static.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.20
-- Language        :   VHDL
-- Description     :   This is static seven seg converter
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_seven_seg_static is
    generic
    (
        hn          : integer := 8                              -- number of seven segments unit
    );
    port
    (
        hex         : in    std_logic_vector(31     downto 0);  -- hexadecimal value input
        cc_ca       : in    std_logic;                          -- common cathode or common anode
        seven_seg   : out   std_logic_vector(hn*8-1 downto 0)   -- seven segments output
    );
end nf_seven_seg_static;

architecture rtl of nf_seven_seg_static is
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

    gen_seven_seg_convertors: 
    for hn_i in 0 to hn-1 generate
        nf_seven_seg_i : nf_seven_seg 
        port map
        (
            hex         =>  hex(hn_i*4 + 3 downto hn_i*4),      -- hexadecimal value input
            cc_ca       =>  cc_ca,                              -- common cathode or common anode
            seven_seg   =>  seven_seg(hn_i*8+7 downto hn_i*8)   -- seven segments output
        );
    end generate gen_seven_seg_convertors;

end rtl; -- nf_seven_seg_static
