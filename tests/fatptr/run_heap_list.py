#!/usr/bin/env python3
"""tests/fatptr heap-list probes (cq-z6q1; CR rules 14, 20, 21; 189's list_search).

For probes/heap_list.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left;
  - each entry keeps its three or four host mallocs (heap records stay host blocks) and decodes next pointers
    at run time (a ptrtoint of a loaded host pointer);
  - the decode is exact (cq-0w0g, owner ruling 2026-11-02): every select of a decoded tag is on
    `icmp eq i64 <loaded addr>, <root base>`, never the one-past range test `icmp ule i64 (addr - base), size`,
    which decodes a pointer to the start of a block placed right after another (real malloc) as the other;
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
Outputs go to build/tests/fatptr/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = Path(__file__).parent / "probes" / "heap_list.O1.ll"
ENTRIES = {"hl_index": 4, "hl_sum": 3}
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def decode_form(b: str) -> list:
    """FileCheck-style: each run-time decode compare is `icmp eq i64 %addr, %base` of two ptrtoints."""
    p2i = set(re.findall(r"(%\d+) = ptrtoint ptr %\d+ to i64", b))
    eqs = re.findall(r"= icmp eq i64 (%\d+), (%\d+)", b)
    if not any(x in p2i and y in p2i for x, y in eqs):
        return ["no exact decode compare (icmp eq i64 of two ptrtoints)"]
    if re.search(r"= sub i64 (%\d+), (%\d+)\n\s*%\d+ = icmp ule i64", b):
        return ["a one-past range decode (sub; icmp ule) is left"]
    return []


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "fatptr" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / "heap_list.lowered.ll"
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(PROBE), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    failures = 0
    for e in ENTRIES:
        why = []
        b = body(mod, e)
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if len(re.findall(r"call [^@]*@malloc\(", b)) != ENTRIES[e]:
            why.append(f"not its {ENTRIES[e]} host mallocs")
        if not re.search(r"= ptrtoint ptr %\d+ to i64", b) or "load ptr" not in b:
            why.append("no run-time decode of a loaded next pointer")
        why += decode_form(b)
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBE), "--lowered", str(lowered),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
