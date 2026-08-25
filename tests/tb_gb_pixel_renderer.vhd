library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

use work.gb_video_pkg.all;

entity tb_gb_pixel_renderer is
end entity;

architecture test of tb_gb_pixel_renderer is
  signal pixel_x        : unsigned(9 downto 0) := (others => '0');
  signal pixel_y        : unsigned(9 downto 0) := (others => '0');
  signal active_video   : std_logic := '0';
  signal viewport_active: std_logic;
  signal shade_debug    : std_logic_vector(1 downto 0);
  signal red            : std_logic_vector(3 downto 0);
  signal green          : std_logic_vector(3 downto 0);
  signal blue           : std_logic_vector(3 downto 0);
begin
  dut : entity work.gb_pixel_renderer
    port map (
      pixel_x         => pixel_x,
      pixel_y         => pixel_y,
      active_video    => active_video,
      viewport_active => viewport_active,
      shade_debug     => shade_debug,
      red             => red,
      green           => green,
      blue            => blue
    );

  stimulus : process
    procedure sample_pixel(
      constant x             : in natural;
      constant y             : in natural;
      constant video_on      : in std_logic;
      constant expected_view : in std_logic;
      constant expected_shade: in std_logic_vector(1 downto 0);
      constant label_text    : in string
    ) is
      variable expected_rgb : std_logic_vector(11 downto 0);
    begin
      pixel_x <= to_unsigned(x, pixel_x'length);
      pixel_y <= to_unsigned(y, pixel_y'length);
      active_video <= video_on;
      wait for 1 ns;
      assert viewport_active = expected_view
        report label_text & ": viewport flag mismatch" severity failure;
      assert shade_debug = expected_shade
        report label_text & ": shade mismatch" severity failure;

      if video_on = '0' or expected_view = '0' then
        assert red = x"0" and green = x"0" and blue = x"0"
          report label_text & ": blanking/outside-viewport pixel was not black" severity failure;
      else
        expected_rgb := palette_rgb(expected_shade);
        assert red & green & blue = expected_rgb
          report label_text & ": palette conversion mismatch" severity failure;
      end if;
    end procedure;
  begin
    sample_pixel(100, 100, '0', '0', "00", "active-video blanking");
    sample_pixel(0, 0, '1', '0', "00", "visible area outside logical viewport");
    sample_pixel(C_VIEW_X, C_VIEW_Y, '1', '1', "11", "logical border pixel");

    -- The sprite's transparent top-left corner exposes background shade 0.
    sample_pixel(C_VIEW_X + (72 * C_SCALE), C_VIEW_Y + (64 * C_SCALE), '1', '1', "00", "transparent sprite corner");

    -- Logical sprite pixel (80,72) is an opaque lower-body pixel at shade 2.
    sample_pixel(C_VIEW_X + (80 * C_SCALE), C_VIEW_Y + (72 * C_SCALE), '1', '1', "10", "sprite priority center");

    -- Every physical pixel in one 3x3 block must map to the same logical pixel.
    sample_pixel(C_VIEW_X + (80 * C_SCALE) + 2, C_VIEW_Y + (72 * C_SCALE) + 2, '1', '1', "10", "three-times scale replication");

    -- The final logical pixel remains inside the centered 160x144 viewport.
    sample_pixel(C_VIEW_X + (C_GB_WIDTH * C_SCALE) - 1,
                 C_VIEW_Y + (C_GB_HEIGHT * C_SCALE) - 1,
                 '1', '1', "11", "logical viewport lower-right border");

    sample_pixel(C_VIEW_X + (C_GB_WIDTH * C_SCALE),
                 C_VIEW_Y + (C_GB_HEIGHT * C_SCALE),
                 '1', '0', "00", "pixel immediately outside logical viewport");

    report "tb_gb_pixel_renderer PASS" severity note;
    stop;
    wait;
  end process;
end architecture;
