# Game Boy VGA Display

**VHDL-2008 VGA display controller for a scaled 160×144 four-shade tile-and-sprite scene.**

![VHDL hardware flow](docs/assets/video-pipeline.svg)

## Design context

The display path began as one part of a 2024 Computer Organization & Architecture team project with **Richard Gill**. This rebuild isolates that idea as a board-agnostic VHDL-2008 controller rather than attempting a complete game system.

I reviewed 640×480 VGA raster timing and nearest-neighbor integer scaling to place a 160×144 logical image inside the active video area. The renderer combines tile and sprite shade values before a four-entry RGB palette, without requiring a framebuffer.

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

## Documentation

- [VHDL source](src/)
- [Architecture notes](docs/ARCHITECTURE.md)
- [Verification notes](docs/VERIFICATION.md)
