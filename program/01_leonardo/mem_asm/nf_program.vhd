library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;

package nf_program is

    constant program : mem_t(4096*4-1 downto 0)(7 downto 0) :=     (         0 => X"B7",
        1 => X"02",
        2 => X"00",
        3 => X"00",
        4 => X"93",
        5 => X"82",
        6 => X"12",
        7 => X"00",
        8 => X"13",
        9 => X"83",
        10 => X"02",
        11 => X"00",
        12 => X"93",
        13 => X"04",
        14 => X"03",
        15 => X"00",
        16 => X"B3",
        17 => X"82",
        18 => X"62",
        19 => X"00",
        20 => X"93",
        21 => X"82",
        22 => X"12",
        23 => X"00",
        24 => X"93",
        25 => X"84",
        26 => X"02",
        27 => X"00",
        28 => X"33",
        29 => X"83",
        30 => X"62",
        31 => X"00",
        32 => X"13",
        33 => X"03",
        34 => X"13",
        35 => X"00",
        36 => X"93",
        37 => X"04",
        38 => X"03",
        39 => X"00",
        40 => X"E3",
        41 => X"04",
        42 => X"00",
        43 => X"FE",
        others => X"XX"
    );

end package nf_program;
