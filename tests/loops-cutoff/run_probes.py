#!/usr/bin/env python3
"""tests/loops-cutoff probes of the widened rule-14 constructions (cq-b58q, owner 2026-11-02: no stops).

Usage: run_probes.py --plugin P --opt O probes/NAME.O1.ll [...]. For each probe file it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left in an entry;
  - every entry (each external `define` in NAME.c) is §6-equal to its own C program (`python3 -m cqcheck user`,
    the C oracle) within a time limit.
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def entries(o1: str):
    return [m.group(1) for m in re.finditer(r"^define (?!internal|private)[^\n]*@(\w+)\(", o1, re.M)
            if "noinline" not in m.group(0)]


def one(a, probe: Path) -> int:
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / probe.name.replace(".O1.ll", ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL {probe.name} cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print(f"FAIL {probe.name} cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    failures = 0
    for e in (a.entry or entries(probe.read_text())):
        why = []
        b = body(mod, e)
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if a.measures is not None and len(re.findall(r"call [^@]*@cqrt_measure_", b)) != a.measures:
            why.append(f"{len(re.findall(r'call [^@]*@cqrt_measure_', b))} cqrt_measure calls, not {a.measures}")
        if a.measures is not None and re.search(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M) and any(
                "cqrt_measure" in t for t in re.findall(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M)):
            why.append("a twin measures")
        try:
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                                str(lowered), "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker",
                               timeout=240)
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        except subprocess.TimeoutExpired:
            why.append("§6 against the C program: timed out")
        print(("FAIL " if why else "ok   ") + probe.name + " " + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append")
    ap.add_argument("--measures", type=int, help="the cqrt_measure calls each entry must hold; no twin may hold one")
    ap.add_argument("probes", nargs="+")
    a = ap.parse_args()
    fails = sum(one(a, Path(p).resolve()) for p in a.probes)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
