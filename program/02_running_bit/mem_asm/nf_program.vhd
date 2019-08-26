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
        8 => X"93",
        9 => X"92",
        10 => X"12",
        11 => X"00",
        12 => X"E3",
        13 => X"8A",
        14 => X"02",
        15 => X"FE",
        16 => X"E3",
        17 => X"0C",
        18 => X"00",
        19 => X"FE",
        others => X"XX"
    );

end package nf_program;
