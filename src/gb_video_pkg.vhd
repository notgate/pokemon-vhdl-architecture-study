library ieee;
use ieee.std_logic_1164.all;

package gb_video_pkg is
  -- Standard 640x480 VGA timing driven by a nominal 25 MHz pixel clock.
  constant C_H_VISIBLE : natural := 640;
  constant C_H_FRONT   : natural := 16;
  constant C_H_SYNC    : natural := 96;
  constant C_H_BACK    : natural := 48;
  constant C_H_TOTAL   : natural := C_H_VISIBLE + C_H_FRONT + C_H_SYNC + C_H_BACK;

  constant C_V_VISIBLE : natural := 480;
  constant C_V_FRONT   : natural := 10;
  constant C_V_SYNC    : natural := 2;
  constant C_V_BACK    : natural := 33;
  constant C_V_TOTAL   : natural := C_V_VISIBLE + C_V_FRONT + C_V_SYNC + C_V_BACK;

  -- A 160x144 logical display is enlarged by integer replication and centered.
  constant C_GB_WIDTH  : natural := 160;
  constant C_GB_HEIGHT : natural := 144;
  constant C_SCALE     : natural := 3;
  constant C_VIEW_X    : natural := (C_H_VISIBLE - (C_GB_WIDTH * C_SCALE)) / 2;
  constant C_VIEW_Y    : natural := (C_V_VISIBLE - (C_GB_HEIGHT * C_SCALE)) / 2;

  subtype shade_t is std_logic_vector(1 downto 0);
  subtype rgb12_t is std_logic_vector(11 downto 0);

  function palette_rgb(shade : shade_t) return rgb12_t;
end package;

package body gb_video_pkg is
  function palette_rgb(shade : shade_t) return rgb12_t is
  begin
    case shade is
      when "00"   => return x"EFD"; -- lightest green
      when "01"   => return x"8C7";
      when "10"   => return x"365";
      when others => return x"012"; -- darkest blue-green
    end case;
  end function;
end package body;
