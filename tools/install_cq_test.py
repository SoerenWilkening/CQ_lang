#!/usr/bin/env python3
"""Focused tests for installer-to-driver backend selection."""

from __future__ import annotations

import argparse
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


if __name__ == "__main__":
    unittest.main()
