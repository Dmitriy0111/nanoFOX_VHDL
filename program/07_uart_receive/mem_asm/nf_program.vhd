library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;

package nf_program is

    constant program : mem_t(4096*4-1 downto 0)(7 downto 0) :=     (         0 => X"63",
        1 => X"00",
        2 => X"00",
        3 => X"00",
        others => X"XX"
    );

end package nf_program;
