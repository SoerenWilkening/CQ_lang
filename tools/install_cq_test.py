#!/usr/bin/env python3
"""Focused tests for installer-to-driver backend selection."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import install_cq


class InstallerSelectionTest(unittest.TestCase):
    def args(self, prefix: Path, backend: str) -> argparse.Namespace:
        return argparse.Namespace(
            prefix=prefix,
            libdir="lib",
            datadir="share",
            backend=backend,
            backend_library=[],
            backend_manifest=None,
            backend_link_item=[],
            llvm_dir=Path("/opt/llvm/lib/cmake/llvm"),
            build_dir=prefix.parent / "build",
            dry_run=False,
        )

    def sourced_values(self, selection: Path) -> list[str]:
        script = (
            'source "$1"; printf "%s\\n" "$CQ_BACKEND_NAME" "$CQ_LLVM_BIN" '
            '"${CQ_BACKEND_LINK_ITEMS[@]}"'
        )
        result = subprocess.run(
            ["bash", "-c", script, "bash", str(selection)],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.splitlines()

    def test_trace_selection_drives_installed_archives(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cq install trace ") as raw:
            prefix = Path(raw)
            args = self.args(prefix, "trace")
            install_cq.install_selection(args)
            prefix = prefix.resolve()

            selection = prefix / "lib/cq/CQBackendSelection.sh"
            self.assertEqual(
                self.sourced_values(selection),
                [
                    "trace",
                    "/opt/llvm/bin",
                    str(prefix / "lib/libcq_templates.a"),
                    str(prefix / "lib/libcq_runtime.a"),
                ],
            )

    def test_external_selection_copies_archives_and_normalizes_libraries(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cq install external ") as raw:
            root = Path(raw)
            prefix = root / "prefix with spaces"
            archive = root / "libbackend.a"
            manifest = root / "backend-manifest.json"
            archive.write_bytes(b"archive")
            manifest.write_text("{}\n", encoding="utf-8")

            args = self.args(prefix, "external")
            args.backend_library = [archive]
            args.backend_manifest = manifest
            args.backend_link_item = ["m", "-pthread", "/opt/lib/libqec.a"]
            install_cq.install_selection(args)
            prefix = prefix.resolve()

            installed = prefix / "lib/cq/backends/external/libbackend.a"
            selection = prefix / "lib/cq/CQBackendSelection.sh"
            self.assertEqual(installed.read_bytes(), b"archive")
            self.assertEqual(
                self.sourced_values(selection),
                [
                    "external",
                    "/opt/llvm/bin",
                    str(installed),
                    "-lm",
                    "-pthread",
                    "/opt/lib/libqec.a",
                ],
            )

    def test_uninstall_manifest_records_cmake_and_generated_files(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cq install manifest ") as raw:
            root = Path(raw)
            prefix = root / "prefix"
            args = self.args(prefix, "trace")
            args.build_dir.mkdir()
            cmake_owned = prefix / "bin/cqc"
            generated = prefix / "lib/cq/CQBackendSelection.sh"
            (args.build_dir / "install_manifest.txt").write_text(
                f"{cmake_owned}\n", encoding="utf-8"
            )

            manifest = install_cq.write_uninstall_manifest(args, [generated])
            self.assertEqual(
                manifest.read_text(encoding="utf-8").splitlines(),
                [
                    "# CQ install manifest v1",
                    str(cmake_owned.resolve()),
                    str(generated.resolve()),
                    str(manifest.resolve()),
                ],
            )

    def make_installed_driver(self, prefix: Path, extra_paths: list[Path]) -> Path:
        driver = prefix / "bin/cqc"
        driver.parent.mkdir(parents=True)
        shutil.copy2(Path(__file__).resolve().parent / "cqc", driver)
        manifest = prefix / "lib/cq/CQInstallManifest.txt"
        manifest.parent.mkdir(parents=True)
        paths = [driver.resolve(), *extra_paths, manifest.resolve()]
        manifest.write_text(
            "# CQ install manifest v1\n" + "".join(f"{path}\n" for path in paths),
            encoding="utf-8",
        )
        return driver

    def test_cqc_uninstall_removes_only_manifest_owned_files(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cq uninstall ") as raw:
            prefix = Path(raw) / "prefix with spaces"
            owned = prefix / "share/cq/owned.txt"
            unrelated = prefix / "keep.txt"
            owned.parent.mkdir(parents=True)
            owned.write_text("owned\n", encoding="utf-8")
            unrelated.write_text("keep\n", encoding="utf-8")
            driver = self.make_installed_driver(prefix, [owned.resolve()])

            result = subprocess.run(
                [str(driver), "--uninstall", "--yes"],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertIn(f"CQ uninstalled from {prefix.resolve()}", result.stdout)
            self.assertFalse(driver.exists())
            self.assertFalse(owned.exists())
            self.assertTrue(unrelated.exists())

    def test_cqc_uninstall_rejects_path_outside_prefix(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cq uninstall unsafe ") as raw:
            root = Path(raw)
            prefix = root / "prefix"
            outside = root / "outside.txt"
            outside.write_text("keep\n", encoding="utf-8")
            driver = self.make_installed_driver(prefix, [outside.resolve()])

            result = subprocess.run(
                [str(driver), "--uninstall", "--yes"],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 3)
            self.assertIn("unsafe uninstall path outside", result.stderr)
            self.assertTrue(driver.exists())
            self.assertTrue(outside.exists())


if __name__ == "__main__":
    unittest.main()
