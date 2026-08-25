from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    def test_rebuild_contains_executable_rtl_and_verification(self):
        expected = [
            "src/gb_video_pkg.vhd",
            "src/vga_timing.vhd",
            "src/gb_pixel_renderer.vhd",
            "src/gb_video_top.vhd",
            "tests/tb_vga_timing.vhd",
            "tests/tb_gb_pixel_renderer.vhd",
            "tests/tb_gb_video_top.vhd",
            "scripts/run_tests.py",
            "scripts/ppm_to_png.py",
            ".github/workflows/vhdl.yml",
        ]
        for relative in expected:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_current_tree_removes_old_software_as_hardware_artifacts(self):
        removed = [
            "docs/Pokemon-VHDL-Project-Report.docx",
            "docs/assets/architecture-diagram.jpg",
            "docs/assets/vga-output-logic.png",
            "docs/assets/vga-simulation-waveform.png",
        ]
        for relative in removed:
            self.assertFalse((ROOT / relative).exists(), relative)

        public_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in [ROOT / "README.md", ROOT / "docs/ARCHITECTURE.md", ROOT / "docs/VERIFICATION.md"]
            if path.exists()
        )
        self.assertNotRegex(
            public_text,
            re.compile(r"battle|encounter|capture logic|game event|profile data|move data|game logic", re.I),
        )

    def test_original_visuals_are_project_owned_and_script_free(self):
        architecture = ROOT / "docs/assets/video-pipeline.svg"
        frame = ROOT / "docs/assets/vga-frame.png"
        self.assertTrue(architecture.is_file())
        self.assertTrue(frame.is_file())
        svg = architecture.read_text(encoding="utf-8")
        self.assertIn("VGA timing", svg)
        self.assertIn("Tile generator", svg)
        self.assertIn("Sprite generator", svg)
        self.assertIn("Priority mux", svg)
        self.assertIn("2-bit palette", svg)
        self.assertNotRegex(svg, re.compile(r"<script|javascript:", re.I))
        self.assertNotRegex(svg, re.compile(r"\b(?:href|src)\s*=\s*['\"]https?://", re.I))
        self.assertGreater(frame.stat().st_size, 2_000)

    def test_readme_claims_are_narrow_and_reproducible(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        for phrase in [
            "VHDL-2008",
            "640×480",
            "160×144",
            "GHDL",
            "python scripts/run_tests.py",
            "simulation-generated",
            "Richard Gill",
        ]:
            self.assertIn(phrase, readme)
        self.assertNotRegex(readme, re.compile(r"emulator|cartridge compatible|cycle[- ]accurate|synthesized on|deployed to", re.I))

    def test_runner_keeps_synthesis_elaboration_as_a_release_gate(self):
        runner = (ROOT / "scripts/run_tests.py").read_text(encoding="utf-8")
        self.assertIn('"--synth"', runner)
        self.assertIn("gb_video_top_synth.vhd", runner)


if __name__ == "__main__":
    unittest.main()
