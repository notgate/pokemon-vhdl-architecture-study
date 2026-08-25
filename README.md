# Game Boy VGA Display

**VHDL-2008 VGA display controller for a scaled 160×144 four-shade tile-and-sprite scene.**

![VHDL hardware flow](docs/assets/video-pipeline.svg)

## Purpose

This project began as the display idea from a 2024 Computer Organization & Architecture team project with **Richard Gill**. I rebuilt that part as a focused VHDL design rather than trying to reproduce a complete game system.

The research focused on 640×480 VGA timing, integer coordinate scaling, tile and sprite pixels, display priority, and four-shade RGB output without a framebuffer.

## Hardware design

- `vga_timing` generates the raster coordinates, HSYNC, and VSYNC.
- `gb_pixel_renderer` maps the active image to a centered 160×144 screen at 3× scale.
- A tile background and transparent sprite produce 2-bit shade values for the RGB palette.
- `gb_video_top` connects the timing and pixel paths.

## Simulation

![Simulation-generated VGA frame](docs/assets/vga-frame.png)

GHDL testbenches check the timing, coordinate mapping, sprite priority, and committed simulation-generated frame.

```text
python scripts/run_tests.py
```

## Project files

- [VHDL source](src/)
- [Architecture notes](docs/ARCHITECTURE.md)
- [Verification notes](docs/VERIFICATION.md)
