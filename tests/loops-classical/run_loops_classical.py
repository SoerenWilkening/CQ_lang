#!/usr/bin/env python3
"""tests/loops-classical (cq-w1-loops-classical): the module's probes through the real plugin.

For probes/loops.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left; every entry with a loop pushes and pops (the reverse ran);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
The owned examples' acceptance is `python3 -m cqcheck run <examples> --oracle both` (the bead).
Outputs go to build/tests/loops-classical/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
PROBE = PROBES / "loops.O1.ll"
# cq-sujx: rule 20 slot cells loaded and stored per trip (58, 60 shapes).
SLOT_PROBE = PROBES / "slots.O1.ll"
SLOT_ENTRIES = ["s_reg", "s_qft", "s_int"]
# Probes cq-lower must stop on with cq::unimplemented carrying this text (nothing emitted).
FATAL = [(PROBES / "slots_fatal_crossgate.O1.ll", "a non-diagonal gate in a classically bounded loop on a rail"),
         # cq-vqid: a record deferred to the reverse loop reads a rail rotated later in the same trip.
         (PROBES / "fatal_undoneread.O1.ll", "a non-diagonal gate in a classically bounded loop on a rail that a "
          "record undone by the reverse loop reads"),
         # cq-pkjc: a quantum arm's classical conjunct (select(i != 0, q[i], false)) the trip does not establish.
         (PROBES / "fatal_armguard.O1.ll", "a block of a classically bounded loop body whose classical guard "
          "(rule 8: the classical factor of its predicate")]
ENTRIES = ["p_acc", "p_brk", "p_nest", "p_mod", "p_nb", "p_horner", "p_arm", "p_phase", "p_cjoin", "p_tphase", "p_bwb", "p_g2"]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def check_probe(a, probe: Path, entries, out: Path) -> int:
    lowered = out / (probe.stem + ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower " + probe.name + ": " + r.stderr.strip())
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify " + probe.name + ": " + v.stderr.strip())
        return 1
    text = lowered.read_text()
    failures = 0
    for e in entries:
        b = body(text, e)
        why = []
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        if "@cqrt_push(" not in b or "@cqrt_pop()" not in b:
            why.append("no push/pop: the reverse loop is missing")
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(lowered),
                            "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
        if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
            why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        print(("FAIL " if why else "ok   ") + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append", help="check only these entries of loops.O1.ll")
    ap.add_argument("--group", action="append", choices=["loops", "slots", "fatal"],
                    help="run only these probe groups (default: all)")
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-classical" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0
    want = set(a.group or (["loops"] if a.entry else ["loops", "slots", "fatal"]))
    groups = []
    if "loops" in want:
        groups.append((PROBE, a.entry or ENTRIES))
    if "slots" in want:
        groups.append((SLOT_PROBE, SLOT_ENTRIES))
    for probe, entries in groups:
        failures += check_probe(a, probe, entries, out)
    if "fatal" in want:
        for probe, msg in FATAL:
            r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                                str(out / (probe.stem + ".lowered.ll"))], capture_output=True, text=True)
            ok = r.returncode != 0 and "cq: unimplemented: loops-classical: " + msg in r.stderr
            print(("ok   " if ok else "FAIL ") + probe.name + ("" if ok else ": expected cq::unimplemented '" + msg +
                                                             "', got exit " + str(r.returncode) + " " +
                                                             r.stderr.strip()[-300:]))
            failures += not ok
    print("FAILED" if failures else "ok")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
