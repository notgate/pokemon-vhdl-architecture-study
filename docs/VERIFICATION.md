# Verification

## Reproduce the result

```text
python scripts/run_tests.py
```

The local verification record was produced with GHDL 6.0.0 in VHDL-2008 mode and Python 3. The GitHub Actions workflow installs the Ubuntu GHDL package and runs the same repository command.

## Test matrix

| Testbench/check | Acceptance criteria |
|---|---|
| `tb_vga_timing` | Every coordinate in one 800×525 frame matches the reference counters; active-video region, active-low sync windows, frame origin, pulse counts, and full-frame wrap are exact |
| `tb_gb_pixel_renderer` | Blanking and margins are black; viewport bounds are inclusive/exclusive at the intended pixels; border shade, transparent sprite pixel, opaque sprite priority, and 3× replication match expected values |
| `tb_gb_video_top` | Integrated outputs produce 307,200 visible VGA samples, exactly 207,360 non-black viewport samples, correct sync counts, and one complete P3 frame |
| GHDL synthesis elaboration | `gb_video_top` and its RTL hierarchy elaborate into a nonempty generated VHDL netlist under `build/` |
| `test_repository.py` | Required RTL/tests/CI exist; historical software-style artifacts are absent; architecture SVG is local and script-free; README claims stay inside the verified scope |

## Generated evidence chain

The displayed PNG is derived from the same integrated top-level outputs that drive the simulated RGB pins:

```text
src/gb_video_top.vhd
        |
tests/tb_gb_video_top.vhd
        |
build/vga-frame.ppm (640x480 RGB samples)
        |
scripts/ppm_to_png.py
        |
docs/assets/vga-frame.png
```

`ppm_to_png.py` uses only the Python standard library and writes deterministic, non-interlaced 8-bit RGB PNG data. The verified frame digest is:

```text
SHA-256 6521e9c7bfa9b5976c8538fae002303619f79c7896b10f1a86aa26eb93fa94f0
```

A normal test run regenerates the image and byte-compares it with the committed artifact. Intentional renderer changes require one explicit refresh:

```text
python scripts/run_tests.py --update-assets
```

## Evidence boundary

The repository verifies RTL analysis, GHDL synthesis elaboration, simulation assertions, synchronization timing, pixel mapping, priority behavior, and a full generated frame. It is board-agnostic and does not attach claims to a particular FPGA, pinout, vendor implementation report, or physical monitor test.
