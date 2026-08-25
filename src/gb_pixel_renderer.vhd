library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gb_video_pkg.all;

entity gb_pixel_renderer is
  port (
    pixel_x         : in  unsigned(9 downto 0);
    pixel_y         : in  unsigned(9 downto 0);
    active_video    : in  std_logic;
    viewport_active : out std_logic;
    shade_debug     : out shade_t;
    red             : out std_logic_vector(3 downto 0);
    green           : out std_logic_vector(3 downto 0);
    blue            : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of gb_pixel_renderer is
  function background_shade(logical_x : natural; logical_y : natural) return shade_t is
    variable tile_x    : natural;
    variable tile_y    : natural;
    variable in_tile_x : natural;
    variable in_tile_y : natural;
    variable tile_kind : natural;
  begin
    if logical_x < 4 or logical_x >= C_GB_WIDTH - 4 or
       logical_y < 4 or logical_y >= C_GB_HEIGHT - 4 then
      return "11";
    end if;

    tile_x := logical_x / 8;
    tile_y := logical_y / 8;
    in_tile_x := logical_x mod 8;
    in_tile_y := logical_y mod 8;
    tile_kind := (tile_x + (2 * tile_y)) mod 4;

    case tile_kind is
      when 0 =>
        if in_tile_x = in_tile_y or in_tile_x + in_tile_y = 7 then
          return "10";
        end if;
        return "00";
      when 1 =>
        if (in_tile_x < 4) xor (in_tile_y < 4) then
          return "01";
        end if;
        return "00";
      when 2 =>
        if in_tile_x = 0 or in_tile_y = 0 then
          return "01";
        end if;
        return "00";
      when others =>
        if (in_tile_x + in_tile_y) mod 4 = 0 then
          return "10";
        end if;
        return "01";
    end case;
  end function;

  function sprite_opaque(sprite_x : natural; sprite_y : natural) return boolean is
  begin
    return
      (sprite_x >= 4 and sprite_x <= 11 and sprite_y >= 1 and sprite_y <= 14) or
      (sprite_x >= 1 and sprite_x <= 14 and sprite_y >= 4 and sprite_y <= 11);
  end function;

  function sprite_shade(sprite_x : natural; sprite_y : natural) return shade_t is
  begin
    if sprite_x = 4 or sprite_x = 11 or sprite_y = 1 or sprite_y = 14 then
      return "11";
    elsif sprite_y = 5 and (sprite_x = 5 or sprite_x = 10) then
      return "11";
    elsif sprite_y < 8 then
      return "01";
    end if;
    return "10";
  end function;
begin
  render : process (all)
    variable physical_x : natural;
    variable physical_y : natural;
    variable logical_x  : natural;
    variable logical_y  : natural;
    variable sprite_x   : natural;
    variable sprite_y   : natural;
    variable shade      : shade_t;
    variable rgb        : rgb12_t;
  begin
    viewport_active <= '0';
    shade_debug <= "00";
    red <= x"0";
    green <= x"0";
    blue <= x"0";

    if active_video = '1' and
       not is_x(std_logic_vector(pixel_x)) and
       not is_x(std_logic_vector(pixel_y)) then
      physical_x := to_integer(pixel_x);
      physical_y := to_integer(pixel_y);

      if physical_x >= C_VIEW_X and physical_x < C_VIEW_X + (C_GB_WIDTH * C_SCALE) and
         physical_y >= C_VIEW_Y and physical_y < C_VIEW_Y + (C_GB_HEIGHT * C_SCALE) then
        logical_x := (physical_x - C_VIEW_X) / C_SCALE;
        logical_y := (physical_y - C_VIEW_Y) / C_SCALE;
        shade := background_shade(logical_x, logical_y);

        if logical_x >= 72 and logical_x < 88 and
           logical_y >= 64 and logical_y < 80 then
          sprite_x := logical_x - 72;
          sprite_y := logical_y - 64;
          if sprite_opaque(sprite_x, sprite_y) then
            shade := sprite_shade(sprite_x, sprite_y);
          end if;
        end if;

        rgb := palette_rgb(shade);
        viewport_active <= '1';
        shade_debug <= shade;
        red <= rgb(11 downto 8);
        green <= rgb(7 downto 4);
        blue <= rgb(3 downto 0);
      end if;
    end if;
  end process;
end architecture;
