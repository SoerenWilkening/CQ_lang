#!/usr/bin/env python3
"""round-2 review, item 3 — NEGATIVE-COVERAGE check over Track M's ACCEPT fixtures.

The fix agent's `vacuity.py` asks "does the handle this negative names EXIST in the
lowered IR?".  This asks the NEXT question (the brief's item 3): "is the handle it
names the USER REGISTER the negative is supposed to be protecting, and is every
user register covered?"  A negative that is non-vacuous but points at an ancilla
(or that simply omits a user register) passes vacuity and still asks nothing.

USER REGISTER, defined mechanically from the LOWERED IR, no hand list:
  a handle that is the target of a `cqrt_ry_*` / `cqrt_ry_*_controlled` (a
  rotation carrier) or the operand of a `cqrt_measure_*` (the user reads it).
ANCILLA: a handle that is `cqrt_free`d.
Reports, per fixture: user registers, which are named by NOX / NOFREE, and any
NOX/NOFREE entry that names a FREED handle (i.e. points at an ancilla).
"""
import re, subprocess, sys, pathlib
ROOT = pathlib.Path("/Users/sorenwilkening/Desktop/CQ_mphi")
CQOPT = ROOT / "build/ir-pass/cq-opt"
PASS = ROOT / "build/ir-pass/libCQPass.so"
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp")
fixtures = sorted(set(list((ROOT/"ir-pass/test").glob("control_swap_accept_select_mergephi_*.ll")) +
                      list((ROOT/"ir-pass/test").glob("control_swap_accept_select_rail_after_prep*.ll"))))
bad = 0
for f in fixtures:
    r = subprocess.run([str(CQOPT), "-load-pass-plugin", str(PASS), "-passes=cq-lowering",
                        "-S", str(f)], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"{f.name}: NOT AN ACCEPT (exit {r.returncode}) — skipped"); continue
    ll = r.stdout
    ry = set(re.findall(r"@cqrt_ry_\w+\(i32 (%[\w.]+)", ll))
    ryc = set(re.findall(r"@cqrt_ry_\w+_controlled\(i32 %[\w.]+, i32 (%[\w.]+)", ll))
    meas = set(re.findall(r"@cqrt_measure_\w+\(i32 (%[\w.]+)", ll))
    freed = set(re.findall(r"@cqrt_free\(i32 (%[\w.]+)", ll))
    users = (ry | ryc | meas) - freed
    src = f.read_text()
    nox = set(re.findall(r"NOX-NOT:\s*call void @cqrt_x\(i32 (%[\w.]+)\)", src))
    nofree = set(re.findall(r"NOFREE-NOT:\s*call void @cqrt_free\(i32 (%[\w.]+)\)", src))
    miss_x = sorted(users - nox); miss_f = sorted(users - nofree)
    anc_x = sorted(nox & freed); anc_f = sorted(nofree & freed)
    undef_x = sorted(n for n in nox if (n+" =") not in ll)
    undef_f = sorted(n for n in nofree if (n+" =") not in ll)
    flag = miss_x or anc_x or undef_x or undef_f
    bad += 1 if flag else 0
    print(f"{f.name}\n  users={sorted(users)} freed={sorted(freed)}\n"
          f"  NOX={sorted(nox)} missing={miss_x} points-at-ancilla={anc_x} undefined={undef_x}\n"
          f"  NOFREE={sorted(nofree)} missing={miss_f} points-at-ancilla={anc_f} undefined={undef_f}\n"
          f"  => {'ATTENTION' if flag else 'ok'}")
print(f"\n{len(fixtures)} fixtures, {bad} with a NOX gap / ancilla-pointing / undefined negative")
