#!/usr/bin/env python3
"""tests/eff-conc (cq-w1-eff-conc): rule 24 probes through the real cq-lower plugin.

For probes/conc.O1.ll and probes/setjmp.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - p_vol_internal drops `volatile` (an unobservable access is the plain one), while
    p_vol_observable keeps both volatile accesses to @obs_counter and p_atomic_classical keeps its
    atomic store and load (the host performs them);
  - every entry is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
probes/*_error.O1.ll must make cq-lower exit non-zero with the named eff-conc internal error: a quantum
value stored to an observable volatile global; an effect in a clone that escapes by longjmp (a _ctl clone,
cq-jwdf); an escaping clone called in a nested frame (the caller's own escaped flag is not built).
p_sj_* (setjmp.O1.ll) are 101's construction (rule 24): a longjmp under a quantum predicate is an escaped
flag the clone returns beside its result, the setjmp join a select on it; no host setjmp/longjmp call is
left. Variants: scalar quantum result, void clone with a pure continuation, classical result, quantum
value on the escaped arm (the != 0 test).
p_vol_local is 32's shape (cq-r4cz): the unobservable volatile slot pair forwards as the plain access;
p_atomic_rmw is 94's (M4): atomicrmw on a slot cell is load + add + store.
The owned example's acceptance is `python3 -m cqcheck run 48_volatile_global --oracle both` (the bead).
Outputs go to build/tests/eff-conc/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
ENTRIES = ["p_vol_internal", "p_vol_observable", "p_atomic_classical", "p_vol_local", "p_atomic_rmw"]
ERRORS = {"vol_quantum_observable_error.O1.ll": "eff-conc: a volatile access to observable memory involving "
                                                "quantum data",
          "setjmp_effect_error.O1.ll": "eff-conc: an escaping clone called as a _ctl clone",
          "setjmp_nested_error.O1.ll": "eff-conc: a setjmp diamond in a lowered function whose first-return arm "
                                       "calls no clone that escapes"}
MODULES = {"conc.O1.ll": ENTRIES, "setjmp.O1.ll": ["p_sj_scalar", "p_sj_void", "p_sj_classical", "p_sj_qarm"]}
_SJ = (r"cq_template_select_i32", r"call [^\n]*@(setjmp|longjmp)\(")
# entry -> (regex that must match its body, regex that must not)
SHAPES = {"p_vol_internal": (None, r"volatile"),
          "p_vol_observable": (r"load volatile i32, ptr @obs_counter[\s\S]*store volatile i32 %\d+, ptr @obs_counter",
                               None),
          "p_atomic_classical": (r"store atomic i32 %\d+, ptr @acell seq_cst[\s\S]*load atomic i32, ptr @acell seq_cst",
                                 None),
          "p_vol_local": (None, r"volatile"),
          "p_atomic_rmw": (r"cq_template_add_i32_hl", r"atomicrmw"),
          "p_sj_scalar": _SJ, "p_sj_void": _SJ, "p_sj_classical": _SJ, "p_sj_qarm": _SJ}


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
    out = ROOT / "build" / "tests" / "eff-conc" / "out"
    out.mkdir(parents=True, exist_ok=True)
    failures = 0

    for name, text in ERRORS.items():
        r = lower(a, PROBES / name, out / ("err_" + name))
        ok = r.returncode != 0 and text in r.stderr
        failures += not ok
        print(f"{'ok' if ok else 'FAIL':4} {name}" + ("" if ok else "\n     expected: " + text + "\n     got: " +
                                                        (r.stderr.strip() or "exit 0")))

    for mod, entries in MODULES.items():
        probe = PROBES / mod
        lowered = out / mod.replace(".O1.ll", ".lowered.ll")
        r = lower(a, probe, lowered)
        if r.returncode != 0:
            print("FAIL cq-lower " + mod + ": " + r.stderr.strip())
            failures += 1
            continue
        v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                            str(lowered)], capture_output=True, text=True)
        if v.returncode != 0:
            print("FAIL cq-verify " + mod + ": " + v.stderr.strip())
            failures += 1
            continue
        text = lowered.read_text()
        for e in entries:
            if a.entry and e not in a.entry:
                continue
            b = body(text, e)
            why = []
            if not b:
                why.append("no lowered body")
            must, mustnot = SHAPES[e]
            if must and not re.search(must, b):
                why.append("missing: " + must)
            if mustnot and re.search(mustnot, b):
                why.append("present: " + mustnot)
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered", str(lowered),
                                "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker")
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("cqcheck user: " + (c.stdout + c.stderr).strip()[-2000:])
            failures += bool(why)
            print(f"{'ok' if not why else 'FAIL':4} {e}" + "".join("\n     " + x for x in why))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
