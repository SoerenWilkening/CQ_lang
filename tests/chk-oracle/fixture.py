"""Test fixture for the C oracle: DriverSpecs and samples from chk-drivers (cqcheck.drivers/sampling).

The oracle renders drivers only through drivers.driver_source (Z1), so these tests need chk-drivers.
Until cq-w0-chk-drivers is merged, CQ_TEST_DRIVERS_DIR may name a checker/cqcheck directory holding
its drivers.py and sampling.py; they are loaded as cqcheck.drivers and cqcheck.sampling.

samples(): the drivers.txt literal calls, then every scalar argument swept over chk-drivers' edge
values and fp specials with the other arguments literal (an oracle stress set, not the SampleSet).
"""
from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))

import cqcheck  # noqa: E402
from cqcheck.contracts import DriverSpec  # noqa: E402


def _load(name: str):
    mod = importlib.import_module(f"cqcheck.{name}")
    alt = os.environ.get("CQ_TEST_DRIVERS_DIR")
    if alt and not hasattr(mod, "driver_source" if name == "drivers" else "sample_set"):
        spec = importlib.util.spec_from_file_location(f"cqcheck.{name}", Path(alt) / f"{name}.py")
        mod = importlib.util.module_from_spec(spec)
        sys.modules[f"cqcheck.{name}"] = mod
        setattr(cqcheck, name, mod)
        spec.loader.exec_module(mod)
    return mod


drivers = _load("drivers")
sampling = _load("sampling")
from cqcheck import oracle  # noqa: E402

SPEC = oracle.SPEC


def names() -> List[str]:
    return sorted(p.name for p in (SPEC / "examples").iterdir() if p.is_dir())


def example_dir(name: str) -> Path:
    return SPEC / "examples" / name


def o1_of(name: str) -> Path:
    return example_dir(name) / f"{name.split('_', 1)[1]}.O1.ll"


def spec_of(name: str) -> DriverSpec:
    return drivers.driver_spec(name, example_dir(name))


def literal_calls(name: str) -> List[List[str]]:
    line = drivers.read_drivers_txt()[name]
    out = []
    for c in line.calls:
        out.append(drivers.parse_call(c)[1])
    return out


def samples(name: str, spec: DriverSpec) -> List[Dict[str, Any]]:
    out = []
    for ci, lits in enumerate(literal_calls(name)):
        cts = [drivers.parse_ctype(a["ctype"]) for a in spec.calls[ci]["args"]]
        base = [sampling.encode_c_literal(ct, v) for ct, v in zip(cts, lits)]
        out.append({"call": ci, "args": base})
        for j, ct in enumerate(cts):
            if ct.kind == "p":
                continue
            vals = (sampling.int_edges(ct) if ct.kind == "i"
                    else sampling.fp_edges(ct) + sampling.fp_specials(ct))
            for v in vals:
                a = list(base)
                a[j] = sampling.hexw(ct, v)
                if a != base:
                    out.append({"call": ci, "args": a})
    return out
