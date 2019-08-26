library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;

package nf_program is

    constant program : mem_t(4096*4-1 downto 0)(7 downto 0) :=     (         0 => X"37",
        1 => X"03",
        2 => X"01",
        3 => X"00",
        4 => X"B7",
        5 => X"03",
        6 => X"00",
        7 => X"00",
        8 => X"93",
        9 => X"83",
        10 => X"03",
        11 => X"02",
        12 => X"B7",
        13 => X"02",
        14 => X"00",
        15 => X"00",
        16 => X"23",
        17 => X"22",
        18 => X"53",
        19 => X"00",
        20 => X"83",
        21 => X"22",
        22 => X"43",
        23 => X"00",
        24 => X"93",
        25 => X"82",
        26 => X"12",
        27 => X"00",
        28 => X"23",
        29 => X"22",
        30 => X"53",
        31 => X"00",
        32 => X"E3",
        33 => X"86",
        34 => X"72",
        35 => X"FE",
        36 => X"E3",
        37 => X"08",
        38 => X"00",
        39 => X"FE",
        others => X"XX"
    );

end package nf_program;
