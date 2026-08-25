from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
SOURCES = [
    ROOT / "src/gb_video_pkg.vhd",
    ROOT / "src/vga_timing.vhd",
    ROOT / "src/gb_pixel_renderer.vhd",
    ROOT / "src/gb_video_top.vhd",
]
TESTBENCHES = [
    ROOT / "tests/tb_vga_timing.vhd",
    ROOT / "tests/tb_gb_pixel_renderer.vhd",
    ROOT / "tests/tb_gb_video_top.vhd",
]
ENTITIES = ["tb_vga_timing", "tb_gb_pixel_renderer", "tb_gb_video_top"]


def run(command: list[str]) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def run_to_file(command: list[str], output: Path) -> None:
    print("+", " ".join(command), ">", output, flush=True)
    with output.open("wb") as stream:
        subprocess.run(command, cwd=ROOT, check=True, stdout=stream)
    if output.stat().st_size == 0:
        raise RuntimeError(f"GHDL produced an empty synthesis netlist: {output}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze and test the VHDL video pipeline with GHDL.")
    parser.add_argument("--ghdl", default=shutil.which("ghdl") or "ghdl")
    parser.add_argument("--update-assets", action="store_true")
    args = parser.parse_args()

    missing = [str(path.relative_to(ROOT)) for path in SOURCES + TESTBENCHES if not path.is_file()]
    if missing:
        print("Missing required source files:", file=sys.stderr)
        for path in missing:
            print(f"  - {path}", file=sys.stderr)
        return 2

    if BUILD.exists():
        shutil.rmtree(BUILD)
    BUILD.mkdir()

    workdir = f"--workdir={BUILD}"
    for source in SOURCES:
        run([args.ghdl, "-a", "--std=08", workdir, str(source)])

    run_to_file(
        [args.ghdl, "--synth", "--std=08", workdir, "gb_video_top"],
        BUILD / "gb_video_top_synth.vhd",
    )

    for source in TESTBENCHES:
        run([args.ghdl, "-a", "--std=08", workdir, str(source)])
    for entity in ENTITIES:
        run([args.ghdl, "-e", "--std=08", workdir, entity])
        run([args.ghdl, "-r", "--std=08", workdir, entity, "--assert-level=error"])

    generated_png = BUILD / "vga-frame.png"
    run([
        sys.executable,
        str(ROOT / "scripts/ppm_to_png.py"),
        "--input",
        str(BUILD / "vga-frame.ppm"),
        "--output",
        str(generated_png),
    ])

    committed_png = ROOT / "docs/assets/vga-frame.png"
    if args.update_assets:
        committed_png.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(generated_png, committed_png)
        print(f"Updated {committed_png.relative_to(ROOT)}")
    elif not committed_png.is_file() or generated_png.read_bytes() != committed_png.read_bytes():
        print("Generated frame does not match docs/assets/vga-frame.png; run with --update-assets.", file=sys.stderr)
        return 3

    run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py"])
    print("All VHDL and repository verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
