#!/usr/bin/env python3
"""tests/aggr (cq-w1-aggr): the module's probes through the real plugin.

For probes/aggr.O1.ll (clang -O1 of aggr.c: vector lanes, shuffles, an overflow struct) and probes/fields.ll
(hand-written nested aggregates), it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left;
  - every entry's template count is exactly the expected one (rule 3: an unread quantum lane gets none,
    extract/insert/shuffle emit none);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
The owned examples' acceptance is `python3 -m cqcheck run <examples> --oracle both` (the bead).
Outputs go to build/tests/aggr/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
# entry -> forward templates expected (cq_template_* calls that are not _unc, rule 6 inverses included)
ENTRIES = {
    "aggr.O1.ll": {
        # w = v + c: lane 0 (lane 1 classical); t = w * w.yx: lane 0 and lane 1 (both read by t.x + t.y);
        # t + shuffle(t): lane 0 only (lane 1 is unread and reads a poison lane)
        "p_vlanes": 4,
        # x * d (scalar); s = v.wzyx + v: lanes 0..3 (each has a quantum term); m, r: 4 + 4; the three xors
        # of lane 0 only (lanes 1..3 are unread), each a bijective update of a dead old lane: + 3 rule 6
        # inverses. x is not cleaned at lane 3 of s: the inverse would read that lane, garbage computed
        # from x (CR rule 6 composite case; uncompute drops it, as for a scalar update).
        "p_vint": 1 + 4 + 4 + 4 + 3 + 3,
        # umul.with.overflow: value and flag templates; zext; add; rule 6's inverse of the add
        "p_ovf": 5,
    },
    "fields.ll": {
        # add, mul, add, xor, and rule 6's inverses of the last add and xor (their old values are dead);
        # no gate for any insertvalue/extractvalue, x is read through field 0 after x + c (kept)
        "p_fields": 6,
        "p_constagg": 7,    # mul, add, sub, xor, and rule 6's inverses of add, sub and xor
    },
}
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")
FWD = re.compile(r"call [^@]*@cq_template_\w+?(?<!_unc)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "aggr" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    for probe, entries in ENTRIES.items():
        src = PROBES / probe
        lowered = out / (probe.split(".")[0] + ".lowered.ll")
        r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src), "-o",
                            str(lowered)], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"FAIL cq-lower {probe}: " + r.stderr.strip())
            failures += 1
            continue
        v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                            str(lowered)], capture_output=True, text=True)
        if v.returncode != 0:
            print(f"FAIL cq-verify {probe}: " + v.stderr.strip())
            failures += 1
            continue
        text = lowered.read_text()
        for e, want in entries.items():
            if a.entry and e not in a.entry:
                continue
            b = body(text, e)
            why = []
            if not b:
                why.append("no lowered body")
            if SURFACE.search(b):
                why.append("a CQ.h surface call is left")
            got = len(FWD.findall(b))
            if got != want:
                why.append(f"{got} forward templates, expected {want}")
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(src), "--lowered", str(lowered),
                                "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
            print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
            failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
