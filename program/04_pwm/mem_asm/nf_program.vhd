library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;

package nf_program is

    constant program : mem_t(4096*4-1 downto 0)(7 downto 0) :=     (         0 => X"37",
        1 => X"03",
        2 => X"02",
        3 => X"00",
        4 => X"B7",
        5 => X"03",
        6 => X"00",
        7 => X"00",
        8 => X"93",
        9 => X"83",
        10 => X"F3",
        11 => X"0F",
        12 => X"B7",
        13 => X"02",
        14 => X"00",
        15 => X"00",
        16 => X"23",
        17 => X"20",
        18 => X"53",
        19 => X"00",
        20 => X"93",
        21 => X"82",
        22 => X"12",
        23 => X"00",
        24 => X"E3",
        25 => X"8A",
        26 => X"72",
        27 => X"FE",
        28 => X"E3",
        29 => X"0A",
        30 => X"00",
        31 => X"FE",
        others => X"XX"
    );

end package nf_program;
