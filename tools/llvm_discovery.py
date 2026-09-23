"""Best-effort discovery of an LLVM 19 CMake package directory."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path


def _cmakedir_from(config: str) -> Path | None:
    try:
        result = subprocess.run(
            [config, "--cmakedir"], check=False, capture_output=True, text=True
        )
    except OSError:
        return None
    if result.returncode:
        return None
    candidate = Path(result.stdout.strip()).expanduser()
    return candidate if candidate.is_dir() else None


def discover_llvm_dir() -> Path | None:
    """Return an LLVM 19 CMake directory, or None for CMake's normal search."""
    configured = os.environ.get("LLVM_DIR")
    if configured:
        return Path(configured).expanduser()

    brew = shutil.which("brew")
    if brew:
        try:
            result = subprocess.run(
                [brew, "--prefix", "llvm@19"],
                check=False, capture_output=True, text=True,
            )
        except OSError:
            result = None
        if result and result.returncode == 0:
            candidate = Path(result.stdout.strip()) / "lib/cmake/llvm"
            if candidate.is_dir():
                return candidate

    for name in ("llvm-config-19", "llvm-config"):
        config = shutil.which(name)
        if not config:
            continue
        try:
            version = subprocess.run(
                [config, "--version"], check=False,
                capture_output=True, text=True,
            ).stdout.strip()
        except OSError:
            continue
        if not re.match(r"^19(?:\.|$)", version):
            continue
        candidate = _cmakedir_from(config)
        if candidate:
            return candidate
    return None
