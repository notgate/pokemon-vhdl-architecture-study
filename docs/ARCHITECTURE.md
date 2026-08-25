# Architecture

## Design objective

The design accepts a nominal 25 MHz pixel clock and produces a complete 640×480 VGA raster. Inside the active area, a 160×144 four-shade logical display is scaled to 480×432 through integer pixel replication and centered with 80-pixel horizontal and 24-pixel vertical margins.

The 25 MHz input produces a 31.25 kHz line rate and an approximately 59.52 Hz frame rate with the standard 800×525 counter geometry. The clock is an input to this repository; board-specific clock generation and pin constraints remain outside the portable RTL.

## Data flow

![Video pipeline](assets/video-pipeline.svg)

```text
pixel_clk/reset
      |
      v
VGA timing -----> HSYNC, VSYNC
      |
      +---- pixel_x, pixel_y, active_video
                         |
                         v
               logical coordinate mapper
                         |
                 +-------+-------+
                 |               |
                 v               v
          tile generator   sprite generator
                 |               |
                 +-------+-------+
                         v
                    priority mux
                         |
                    2-bit shade
                         |
                         v
                  12-bit RGB palette
```

There is no software event loop or frame-buffer dependency. Pixel color is a deterministic function of the current raster coordinate and the renderer constants.

## Timing constants

| Quantity | Visible | Front porch | Sync | Back porch | Total |
|---|---:|---:|---:|---:|---:|
| Horizontal pixels | 640 | 16 | 96 | 48 | 800 |
| Vertical lines | 480 | 10 | 2 | 33 | 525 |

Both synchronization outputs are active-low. `active_video` is high only while `pixel_x < 640` and `pixel_y < 480`.

## Logical viewport

The renderer accepts pixels only within:

```text
80 <= pixel_x < 560
24 <= pixel_y < 456
```

For those pixels:

```text
logical_x = floor((pixel_x - 80) / 3)
logical_y = floor((pixel_y - 24) / 3)
```

This maps the VGA coordinates to `0..159` by `0..143`. Division by the constant scale factor implements nearest-neighbor pixel replication: every logical pixel produces one 3×3 physical block.

## Background and sprite paths

`gb_pixel_renderer.vhd` contains two independent combinational pixel sources:

- an 8×8 procedural tile pattern selected from logical tile coordinates;
- one original 16×16 cross-shaped sprite with transparent corner pixels.

The sprite path provides an opacity decision and a 2-bit shade. The priority mux uses the sprite shade only when that pixel is opaque; otherwise the tile shade passes through. This keeps the hardware boundary explicit and the implementation centered on raster generation.

## Palette

The final 2-bit shade indexes a fixed four-entry 12-bit RGB palette:

| Shade | RGB 4:4:4 | Role |
|---|---|---|
| `00` | `EFD` | lightest |
| `01` | `8C7` | light |
| `10` | `365` | dark |
| `11` | `012` | darkest |

Pixels outside the logical viewport and all pixels during blanking output black.

## Design units

| File | Responsibility |
|---|---|
| `src/gb_video_pkg.vhd` | Shared timing, viewport, scale, shade, and palette definitions |
| `src/vga_timing.vhd` | Horizontal/vertical counters, active-video flag, frame marker, HSYNC, and VSYNC |
| `src/gb_pixel_renderer.vhd` | Coordinate mapping, tile generation, sprite generation, priority, and palette |
| `src/gb_video_top.vhd` | Portable timing-to-renderer integration |
