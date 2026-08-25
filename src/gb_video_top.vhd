library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gb_video_top is
  port (
    pixel_clk : in  std_logic;
    reset     : in  std_logic;
    hsync     : out std_logic;
    vsync     : out std_logic;
    red       : out std_logic_vector(3 downto 0);
    green     : out std_logic_vector(3 downto 0);
    blue      : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of gb_video_top is
  signal pixel_x         : unsigned(9 downto 0) := (others => '0');
  signal pixel_y         : unsigned(9 downto 0) := (others => '0');
  signal active_video    : std_logic := '0';
  signal viewport_active : std_logic := '0';
  signal shade_debug     : std_logic_vector(1 downto 0) := (others => '0');
begin
  timing : entity work.vga_timing
    port map (
      pixel_clk    => pixel_clk,
      reset        => reset,
      hsync        => hsync,
      vsync        => vsync,
      active_video => active_video,
      frame_start  => open,
      pixel_x      => pixel_x,
      pixel_y      => pixel_y
    );

  renderer : entity work.gb_pixel_renderer
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
end architecture;
