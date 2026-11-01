#!/usr/bin/env python3
"""tests/fatptr (cq-w1-fatptr): rule 21 fat pointers through the real cq-lower plugin.

Fails on any of:
  - probes/fatptr.O1.ll (from fatptr.c): cq-lower (with its built-in verifier) exits non-zero, plain
    cq-verify rejects the output, a CQ.h surface call is left, an entry has no fat-pointer construction
    (no template on an i32 tag or an i64 address), or an entry is not §6-equal to its own C program
    (`python3 -m cqcheck user`, the C oracle);
  - every other probes/*.ll carries `; EXPECT-ERROR: <text>`: cq-lower must exit non-zero with <text>
    on stderr (an internal error, never a lowering).
The owned example's acceptance is `python3 -m cqcheck run 86_ptrdiff_compare --oracle both` (the bead).
Outputs go to build/tests/fatptr/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
PROBE = PROBES / "fatptr.O1.ll"
ENTRIES = ["f_ne_two", "f_eq_three", "f_eq_arms", "f_lt_global", "f_eq_signed", "f_rail_off", "f_rail_off_store", "f_ptrmask",
           "f_ret_ptr", "f_slot_rmw", "f_slot_rmw_old", "f_slot_peek", "f_field_store",
           # cq-b244: roots inside their objects (&t[4]) at negative cell indices
           "f_neg_qrom", "f_neg_qrom_sext", "f_neg_cmp", "f_neg_inttoptr"]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")
FAT = re.compile(r"@cq_template_(select_i32|icmp_eq_i32|icmp_ne_i32|\w+_i64)")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def lower(a, src: Path, dest: Path):
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src), "-o",
                           str(dest)], capture_output=True, text=True)


def expect_errors(a, out: Path) -> int:
    failures = 0
    for p in sorted(PROBES.glob("*.ll")):
        if p == PROBE:
            continue
        m = re.search(r"^; EXPECT-ERROR: (.*)$", p.read_text(), re.M)
        r = lower(a, p, out / ("probe_" + p.name))
        why = ""
        if not m:
            why = "no EXPECT-ERROR line"
        elif r.returncode == 0:
            why = "cq-lower succeeded; expected: " + m.group(1)
        elif m.group(1) not in r.stderr:
            why = "cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0]
        print(("FAIL " if why else "ok   ") + "probe " + p.name + ("" if not why else ": " + why))
        failures += bool(why)
    return failures


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "fatptr" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = expect_errors(a, out)
    lowered = out / "fatptr.lowered.ll"
    r = lower(a, PROBE, lowered)
    if r.returncode != 0:
        print("FAIL cq-lower: " + r.stderr.strip())
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify: " + v.stderr.strip())
        return 1
    text = lowered.read_text()
    for e in a.entry or ENTRIES:
        b = body(text, e)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if not FAT.search(b):
            why.append("no fat-pointer construction")
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBE), "--lowered", str(lowered),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
