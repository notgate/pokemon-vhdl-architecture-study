library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gb_video_pkg.all;

entity vga_timing is
  port (
    pixel_clk    : in  std_logic;
    reset        : in  std_logic;
    hsync        : out std_logic;
    vsync        : out std_logic;
    active_video : out std_logic;
    frame_start  : out std_logic;
    pixel_x      : out unsigned(9 downto 0);
    pixel_y      : out unsigned(9 downto 0)
  );
end entity;

architecture rtl of vga_timing is
  signal h_count : natural range 0 to C_H_TOTAL - 1 := 0;
  signal v_count : natural range 0 to C_V_TOTAL - 1 := 0;
begin
  counters : process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      if reset = '1' then
        h_count <= 0;
        v_count <= 0;
      elsif h_count = C_H_TOTAL - 1 then
        h_count <= 0;
        if v_count = C_V_TOTAL - 1 then
          v_count <= 0;
        else
          v_count <= v_count + 1;
        end if;
      else
        h_count <= h_count + 1;
      end if;
    end if;
  end process;

  pixel_x <= to_unsigned(h_count, pixel_x'length);
  pixel_y <= to_unsigned(v_count, pixel_y'length);

  active_video <= '1' when h_count < C_H_VISIBLE and v_count < C_V_VISIBLE else '0';
  frame_start <= '1' when h_count = 0 and v_count = 0 else '0';

  hsync <= '0' when
    h_count >= C_H_VISIBLE + C_H_FRONT and
    h_count < C_H_VISIBLE + C_H_FRONT + C_H_SYNC
    else '1';

  vsync <= '0' when
    v_count >= C_V_VISIBLE + C_V_FRONT and
    v_count < C_V_VISIBLE + C_V_FRONT + C_V_SYNC
    else '1';
end architecture;
