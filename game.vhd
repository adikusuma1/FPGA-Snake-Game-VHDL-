library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game is
    port(
        clk_50mhz           : in  std_logic;
        reset               : in  std_logic;
        button              : in  std_logic_vector(4 downto 0);
        hout, vout          : out std_logic;
        led                 : out std_logic_vector(7 downto 0); --UNTUK DEBUG
        rout, gout, bout    : out std_logic);
end entity;

architecture arch of game is

    component game_logic_and_rgb_gen
        port(
            --game logic part
            clk_60hz            : in  std_logic;
            direction           : in  std_logic_vector(1 downto 0);
            stop                : in  std_logic;
            reset               : in  std_logic;
            --rgb generation part
            clk_50mhz           : in  std_logic;
            en                  : in  std_logic;
            row, col            : in  std_logic_vector(15 downto 0);
            debug_led           : out std_logic_vector(7 downto 0);
            rout, gout, bout    : out std_logic);
    end component;

	 component joypad
        port(
            clk_60hz    : in  std_logic;
            button      : in std_logic_vector(4 downto 0);
            stop        : out std_logic;
            direction   : out std_logic_vector(1 downto 0));
    end component;

    component vga_core
        port(
            clk             : in  std_logic;        --virtual clock called per pixel, should be 108mhz for 1600x900
            en              : out std_logic;        --if display is enabled
            h_sync, v_sync  : out std_logic;        --if horizontal or vertical sync 
            row, col        : out std_logic_vector(15 downto 0));     --row and col of the pixel need to be displayed
    end component;

    signal sg_clk_60hz			     	: std_logic;
    signal joypad_direction         : std_logic_vector(1 downto 0);
    signal joypad_stop              : std_logic;
    signal vga_en                   : std_logic;
    signal vga_row, vga_col         : std_logic_vector(15 downto 0);

begin

use_game_logic_and_rgb_gen:
    game_logic_and_rgb_gen port map(
        clk_60hz    => sg_clk_60hz,
        direction   => joypad_direction,
        stop        => joypad_stop,
        reset       => reset,
        clk_50mhz   => clk_50mhz,
        en      	  => vga_en,
        row     	  => vga_row,
        col     	  => vga_col,
        debug_led   => led,
        rout    	  => rout,
        gout    	  => gout,
        bout    	  => bout);

use_vga_core:
    vga_core port map(
        clk     => clk_50mhz,
        en      => vga_en,
        h_sync  => hout,
        v_sync  => vout,
        row     => vga_row,
        col     => vga_col);

use_joypad:
    joypad port map(
        clk_60hz    => sg_clk_60hz,
        button      => button,
        stop        => joypad_stop,
        direction   => joypad_direction);

--SESUAIKAN counter DENGAN SUMBER CLOCK 50MHZ
use_clk_60hz:
    process(clk_50mhz)
        --counter reverts in 50mhz / 60hz / 2 = 416667
        constant counter_max    : integer := 416667;

        variable counter        : integer range 0 to counter_max - 1 := 0;
        variable clk_60hz_future: std_logic := '0';
    begin 
        if (clk_50mhz'event and clk_50mhz = '1') then 
            if (counter = counter_max - 1) then
                counter := 0;
                clk_60hz_future := not clk_60hz_future;
            else
                counter := counter + 1;
            end if;
        end if;
        sg_clk_60hz <= clk_60hz_future;
    end process;

end arch;
