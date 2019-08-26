library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;

package nf_program is

    constant program : mem_t(4096*4-1 downto 0)(7 downto 0) :=     (         0 => X"37",
        1 => X"07",
        2 => X"03",
        3 => X"00",
        4 => X"93",
        5 => X"06",
        6 => X"40",
        7 => X"00",
        8 => X"93",
        9 => X"07",
        10 => X"80",
        11 => X"04",
        12 => X"13",
        13 => X"06",
        14 => X"20",
        15 => X"1B",
        16 => X"23",
        17 => X"26",
        18 => X"C7",
        19 => X"00",
        20 => X"23",
        21 => X"20",
        22 => X"D7",
        23 => X"00",
        24 => X"23",
        25 => X"22",
        26 => X"F7",
        27 => X"00",
        28 => X"93",
        29 => X"06",
        30 => X"50",
        31 => X"00",
        32 => X"23",
        33 => X"20",
        34 => X"D7",
        35 => X"00",
        36 => X"83",
        37 => X"25",
        38 => X"07",
        39 => X"00",
        40 => X"E3",
        41 => X"8E",
        42 => X"B6",
        43 => X"FE",
        44 => X"37",
        45 => X"07",
        46 => X"01",
        47 => X"00",
        48 => X"23",
        49 => X"22",
        50 => X"F7",
        51 => X"00",
        52 => X"6F",
        53 => X"00",
        54 => X"00",
        55 => X"00",
        56 => X"6F",
        57 => X"00",
        58 => X"00",
        59 => X"00",
        60 => X"6F",
        61 => X"00",
        62 => X"00",
        63 => X"00",
        64 => X"6F",
        65 => X"00",
        66 => X"00",
        67 => X"00",
        others => X"XX"
    );

end package nf_program;
