#!/usr/bin/env python3
"""tests/eff-invert (cq-w1-eff-invert): rule 17 probes through the real cq-lower plugin.

For each probe file in CHECKED it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call and no asm fence is left in any entry;
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle, which negates
    the angles of the sites inside a cq_invert region).
probes/*_error.O1.ll must make cq-lower exit non-zero with an eff-invert internal error: a region whose
quantum value is read after it (no adjoint under rule 17), markers -O1 duplicated into quantum arms
(cq-asfn, not built yet; update this test when it is), a rotation between a region template and its
uncompute (rule 5) and a classical conjunct of a quantum arm condition (rule 8 guard).
probes/invert_loop.O1.ll (a classical loop in a region) and probes/invert_adj.O1.ll (an _adj clone) are
checked like invert.O1.ll.
The owned example's acceptance is `python3 -m cqcheck run 44_invert_bracket --oracle both` (the bead).
Outputs go to build/tests/eff-invert/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
CHECKED = {"invert.O1.ll": ["p_flat", "p_arms", "p_nest", "p_around", "p_two"],
           "invert2.O1.ll": ["p_inplace", "p_cbr", "p_reg", "p_cswitch"],
           "invert_loop.O1.ll": ["p_cloop"],
           "invert_adj.O1.ll": ["p_adj"]}
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(|call void asm")
SESE = "eff-invert: a cq_invert region that is not single-entry single-exit"
ERRORS = {"region_output_error.O1.ll": "eff-invert: a quantum value of a cq_invert region read after it",
          # cq-asfn: -O1 duplicates a marker into the arms of a quantum branch; not built yet.
          "dup_begin_error.O1.ll": SESE, "dup_end_error.O1.ll": SESE,
          "barrier_error.O1.ll": "eff-invert: a non-diagonal gate inside a cq_invert region on a rail a template "
                                 "of the region reads (rule 5)",
          "guard_error.O1.ll": "eff-invert: a quantum arm inside a cq_invert region whose block predicate has a "
                               "classical conjunct"}


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def lower(a, src: Path, dest: Path):
    return subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(src), "-o",
                           str(dest)], capture_output=True, text=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "eff-invert" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0

    for name, text in ERRORS.items():
        r = lower(a, PROBES / name, out / ("err_" + name))
        ok = r.returncode != 0 and text in r.stderr
        failures += not ok
        print(f"{'ok' if ok else 'FAIL':4} {name}" + ("" if ok else "\n     expected: " + text + "\n     got: " +
                                                        (r.stderr.strip() or "exit 0")))

    for name, entries in CHECKED.items():
        probe = PROBES / name
        lowered = out / name.replace(".O1.ll", ".lowered.ll")
        r = lower(a, probe, lowered)
        if r.returncode != 0:
            failures += 1
            print(f"FAIL cq-lower {name}: " + r.stderr.strip())
            continue
        v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                            str(lowered)], capture_output=True, text=True)
        if v.returncode != 0:
            failures += 1
            print(f"FAIL cq-verify {name}: " + v.stderr.strip())
            continue
        text = lowered.read_text()
        for e in entries:
            if a.entry and e not in a.entry:
                continue
            b = body(text, e)
            why = []
            if not b:
                why.append("no lowered body")
            if SURFACE.search(b):
                why.append("a CQ.h surface call or an asm fence is left")
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                                str(lowered), "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("cqcheck user: " + (c.stdout + c.stderr).strip()[-2000:])
            failures += bool(why)
            print(f"{'ok' if not why else 'FAIL':4} {e}" + "".join("\n     " + x for x in why))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
