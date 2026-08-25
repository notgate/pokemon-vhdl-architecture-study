library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

use work.gb_video_pkg.all;

entity tb_vga_timing is
end entity;

architecture test of tb_vga_timing is
  signal pixel_clk    : std_logic := '0';
  signal reset        : std_logic := '1';
  signal hsync        : std_logic;
  signal vsync        : std_logic;
  signal active_video : std_logic;
  signal frame_start  : std_logic;
  signal pixel_x      : unsigned(9 downto 0);
  signal pixel_y      : unsigned(9 downto 0);
begin
  pixel_clk <= not pixel_clk after 20 ns;

  dut : entity work.vga_timing
    port map (
      pixel_clk    => pixel_clk,
      reset        => reset,
      hsync        => hsync,
      vsync        => vsync,
      active_video => active_video,
      frame_start  => frame_start,
      pixel_x      => pixel_x,
      pixel_y      => pixel_y
    );

  stimulus : process
    variable expected_x    : natural := 0;
    variable expected_y    : natural := 0;
    variable hsync_low     : natural := 0;
    variable vsync_low     : natural := 0;
    variable active_pixels : natural := 0;
  begin
    wait for 100 ns;
    wait until falling_edge(pixel_clk);
    reset <= '0';
    wait for 1 ns;

    for sample in 0 to (C_H_TOTAL * C_V_TOTAL) - 1 loop
      assert to_integer(pixel_x) = expected_x
        report "horizontal counter mismatch at sample " & integer'image(sample)
        severity failure;
      assert to_integer(pixel_y) = expected_y
        report "vertical counter mismatch at sample " & integer'image(sample)
        severity failure;

      if expected_x < C_H_VISIBLE and expected_y < C_V_VISIBLE then
        assert active_video = '1' report "active video missing inside visible area" severity failure;
        active_pixels := active_pixels + 1;
      else
        assert active_video = '0' report "active video asserted during blanking" severity failure;
      end if;

      if expected_x >= C_H_VISIBLE + C_H_FRONT and
         expected_x < C_H_VISIBLE + C_H_FRONT + C_H_SYNC then
        assert hsync = '0' report "HSYNC must be active-low inside its pulse" severity failure;
        hsync_low := hsync_low + 1;
      else
        assert hsync = '1' report "HSYNC must be high outside its pulse" severity failure;
      end if;

      if expected_y >= C_V_VISIBLE + C_V_FRONT and
         expected_y < C_V_VISIBLE + C_V_FRONT + C_V_SYNC then
        assert vsync = '0' report "VSYNC must be active-low inside its pulse" severity failure;
        vsync_low := vsync_low + 1;
      else
        assert vsync = '1' report "VSYNC must be high outside its pulse" severity failure;
      end if;

      if expected_x = 0 and expected_y = 0 then
        assert frame_start = '1' report "frame_start missing at origin" severity failure;
      else
        assert frame_start = '0' report "frame_start asserted away from origin" severity failure;
      end if;

      wait until rising_edge(pixel_clk);
      wait for 1 ps;
      if expected_x = C_H_TOTAL - 1 then
        expected_x := 0;
        if expected_y = C_V_TOTAL - 1 then
          expected_y := 0;
        else
          expected_y := expected_y + 1;
        end if;
      else
        expected_x := expected_x + 1;
      end if;
    end loop;

    assert active_pixels = C_H_VISIBLE * C_V_VISIBLE
      report "visible pixel count mismatch" severity failure;
    assert hsync_low = C_H_SYNC * C_V_TOTAL
      report "HSYNC pulse width/count mismatch" severity failure;
    assert vsync_low = C_V_SYNC * C_H_TOTAL
      report "VSYNC pulse height/count mismatch" severity failure;
    assert pixel_x = to_unsigned(0, pixel_x'length) and pixel_y = to_unsigned(0, pixel_y'length)
      report "counters did not wrap after one complete frame" severity failure;

    report "tb_vga_timing PASS" severity note;
    stop;
    wait;
  end process;
end architecture;
