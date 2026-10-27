#!/usr/bin/env python3
"""cq-5k5: the taint the constructions read is computed over the final CFG.

Owner ruling on cq-5k5, option (a): a preliminary computeTaint is used only for isTainted(F);
FixIrreduciblePass runs on those functions; if any function changed, a fresh computeTaint runs over
the module with the preliminary result discarded; then construct. The pass's private flag
-cq-trace-pipeline prints one stderr line before each step, which is what this test reads.

Inputs:
  irreducible/irreducible_tainted.ll  @tainted: an irreducible cycle entered on a quantum branch;
                                      @classical: the same cycle on a classical branch.
  CQ_spec examples/01_add_classical_const  a reducible tainted function.

Precondition (always checked): plain `opt -passes=fix-irreducible` rewrites @tainted, so the input
exercises the changed-CFG path.

Required trace once module taint answers computeTaint and isTainted:
  irreducible: taint: preliminary / fix-irreducible: changed @tainted (and never @classical) /
               taint: final (fresh, CFG changed) / construct
  reducible:   taint: preliminary / taint: final (preliminary, CFG unchanged) / construct
After `construct` the run may complete or stop at another module's cq: unimplemented; that is not
this test's subject.

While computeTaint is still the scaffold stub, the only observable fact is that nothing runs before
the preliminary taint: the trace is exactly `taint: preliminary` followed by
`cq: unimplemented: taint: computeTaint`, with no output. The test then prints PENDING and the
second computeTaint is NOT observed. Any other outcome fails.

Usage: check_taint_final.py --plugin build/pass/libCQLower.so [--opt OPT] [--spec DIR]
"""
import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
LLVM = Path("/usr/local/opt/llvm@19/bin")
TRACE = re.compile(r"^cq-lower: (.*)$")
ERROR = re.compile(r"^LLVM ERROR: (.*)$")
TAINT_STUB = "cq: unimplemented: taint: computeTaint"

failures = []
pending = []


def fail(msg):
    failures.append(msg)
    print("FAIL:", msg)


def function_body(ir, name):
    m = re.search(r"^define [^\n]*@" + re.escape(name) + r"\(.*?^}", ir, re.M | re.S)
    return m.group(0) if m else None


def run_lower(opt, plugin, src):
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.ll"
        p = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower",
                            "-cq-trace-pipeline", "-S", str(src), "-o", str(out)],
                           capture_output=True, text=True)
        wrote = out.exists() and out.stat().st_size > 0
    steps, errors = [], []
    for line in p.stderr.splitlines():
        if (m := TRACE.match(line)):
            steps.append(m.group(1))
        elif (m := ERROR.match(line)):
            errors.append(m.group(1))
    return p, steps, errors, wrote


def check(label, opt, plugin, src, expected):
    p, steps, errors, wrote = run_lower(opt, plugin, src)
    if steps == ["taint: preliminary"] and errors == [TAINT_STUB]:
        if p.returncode == 0 or wrote or p.stdout:
            fail(f"{label}: taint stub hit but the run exited 0 or emitted output")
        else:
            pending.append(label)
            print(f"PENDING: {label}: computeTaint is the stub; only 'nothing runs before the "
                  f"preliminary taint' is observed, the final taint is not")
        return
    if any(s.startswith("fix-irreducible: changed @classical") for s in steps):
        fail(f"{label}: @classical carries no taint but was rewritten")
    if steps[:len(expected)] != expected:
        fail(f"{label}: trace {steps} does not start with {expected}; errors {errors}")
        return
    extra = steps[len(expected):]
    if extra:
        fail(f"{label}: trace lines after 'construct': {extra}")
    if errors and p.returncode == 0:
        fail(f"{label}: LLVM ERROR {errors} with exit 0")
    status = "completed" if p.returncode == 0 else f"stopped after construct: {errors}"
    print(f"ok: {label}: {' / '.join(expected)} ({status})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", default=str(LLVM / "opt"))
    ap.add_argument("--spec", default=str(HERE.parents[1] / ".." / "CQ_spec"))
    a = ap.parse_args()

    irr = HERE / "irreducible" / "irreducible_tainted.ll"
    red = Path(a.spec) / "examples" / "01_add_classical_const" / "add_classical_const.O1.ll"
    for f in (irr, red):
        if not f.is_file():
            fail(f"missing input {f}")
    if failures:
        return 1

    p = subprocess.run([a.opt, "-S", "-passes=fix-irreducible", str(irr)], capture_output=True, text=True)
    body = function_body(p.stdout, "tainted") if p.returncode == 0 else None
    before = function_body(irr.read_text(), "tainted")
    if not body or "irr.guard" not in body or "irr.guard" in (before or ""):
        fail("precondition: plain fix-irreducible does not rewrite @tainted")
    else:
        print("ok: precondition: plain fix-irreducible rewrites @tainted")

    check("irreducible", a.opt, a.plugin, irr,
          ["taint: preliminary", "fix-irreducible: changed @tainted",
           "taint: final (fresh, CFG changed)", "construct"])
    check("reducible", a.opt, a.plugin, red,
          ["taint: preliminary", "taint: final (preliminary, CFG unchanged)", "construct"])

    print(f"check_taint_final: {len(failures)} failure(s), {len(pending)} pending")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
