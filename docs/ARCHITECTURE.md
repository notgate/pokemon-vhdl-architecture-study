# Architecture

## Design

The design accepts a nominal 25 MHz pixel clock and produces a complete 640×480 VGA raster. Inside the active area, a 160×144 four-shade logical display is scaled to 480×432 through integer pixel replication and centered with 80-pixel horizontal and 24-pixel vertical margins.

The 25 MHz input produces a 31.25 kHz line rate and an approximately 59.52 Hz frame rate with the standard 800×525 counter geometry.

## Data flow

![Video pipeline](assets/video-pipeline.svg)

There is no software event loop or frame-buffer dependency. Pixel color is a deterministic function of the current raster coordinate and the renderer constants.

## Timing constants

| Quantity | Visible | Front porch | Sync | Back porch | Total |
|---|---:|---:|---:|---:|---:|
| Horizontal pixels | 640 | 16 | 96 | 48 | 800 |
| Vertical lines | 480 | 10 | 2 | 33 | 525 |

Both synchronization outputs are active-low. `active_video` is high only while `pixel_x < 640` and `pixel_y < 480`.

## Color palette

The final 2-bit shade indexes a fixed four-entry 12-bit RGB palette:

| Shade | RGB 4:4:4 | Role |
|---|---|---|
| `00` | `EFD` | lightest |
| `01` | `8C7` | light |
| `10` | `365` | dark |
| `11` | `012` | darkest |

Pixels outside the logical viewport and all pixels during blanking output black.

## File stuff

| File | Responsibility |
|---|---|
| `src/gb_video_pkg.vhd` | Shared timing, viewport, scale, shade, and palette definitions |
| `src/vga_timing.vhd` | Horizontal/vertical counters, active-video flag, frame marker, HSYNC, and VSYNC |
| `src/gb_pixel_renderer.vhd` | Coordinate mapping, tile generation, sprite generation, priority, and palette |
| `src/gb_video_top.vhd` | Portable timing-to-renderer integration |
