library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library std;
use std.env.all;

use work.gb_video_pkg.all;

entity tb_gb_video_top is
end entity;

architecture test of tb_gb_video_top is
  signal pixel_clk : std_logic := '0';
  signal reset     : std_logic := '1';
  signal hsync     : std_logic;
  signal vsync     : std_logic;
  signal red       : std_logic_vector(3 downto 0);
  signal green     : std_logic_vector(3 downto 0);
  signal blue      : std_logic_vector(3 downto 0);
begin
  pixel_clk <= not pixel_clk after 20 ns;

  dut : entity work.gb_video_top
    port map (
      pixel_clk => pixel_clk,
      reset     => reset,
      hsync     => hsync,
      vsync     => vsync,
      red       => red,
      green     => green,
      blue      => blue
    );

  stimulus : process
    file frame_file : text open write_mode is "build/vga-frame.ppm";
    variable output_line    : line;
    variable expected_x     : natural := 0;
    variable expected_y     : natural := 0;
    variable written_pixels : natural := 0;
    variable colored_pixels : natural := 0;
    variable hsync_low      : natural := 0;
    variable vsync_low      : natural := 0;
    variable r8             : natural;
    variable g8             : natural;
    variable b8             : natural;
  begin
    wait for 100 ns;
    wait until falling_edge(pixel_clk);
    reset <= '0';
    wait for 1 ns;

    write(output_line, string'("P3"));
    writeline(frame_file, output_line);
    write(output_line, integer'image(C_H_VISIBLE) & " " & integer'image(C_V_VISIBLE));
    writeline(frame_file, output_line);
    write(output_line, string'("255"));
    writeline(frame_file, output_line);

    for sample in 0 to (C_H_TOTAL * C_V_TOTAL) - 1 loop
      if hsync = '0' then
        hsync_low := hsync_low + 1;
      end if;
      if vsync = '0' then
        vsync_low := vsync_low + 1;
      end if;

      if expected_x < C_H_VISIBLE and expected_y < C_V_VISIBLE then
        r8 := to_integer(unsigned(red)) * 17;
        g8 := to_integer(unsigned(green)) * 17;
        b8 := to_integer(unsigned(blue)) * 17;
        write(output_line, integer'image(r8) & " " & integer'image(g8) & " " & integer'image(b8));
        writeline(frame_file, output_line);
        written_pixels := written_pixels + 1;
        if r8 /= 0 or g8 /= 0 or b8 /= 0 then
          colored_pixels := colored_pixels + 1;
        end if;
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

    assert written_pixels = C_H_VISIBLE * C_V_VISIBLE
      report "rendered frame pixel count mismatch" severity failure;
    assert colored_pixels = (C_GB_WIDTH * C_SCALE) * (C_GB_HEIGHT * C_SCALE)
      report "logical viewport area did not render exactly" severity failure;
    assert hsync_low = C_H_SYNC * C_V_TOTAL
      report "integration HSYNC count mismatch" severity failure;
    assert vsync_low = C_V_SYNC * C_H_TOTAL
      report "integration VSYNC count mismatch" severity failure;

    report "tb_gb_video_top PASS; generated build/vga-frame.ppm" severity note;
    stop;
    wait;
  end process;
end architecture;
