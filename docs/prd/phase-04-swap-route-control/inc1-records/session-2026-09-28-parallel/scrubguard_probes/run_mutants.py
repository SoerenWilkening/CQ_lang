#!/usr/bin/env python3
"""Run a SUBSET of the guard's own self-test mutants (by label substring) against THIS
worktree's tools/taintset_scrub_guard.py, printing each verdict and its first problems.
usage: run_mutants.py [--no-pch] <substring> [<substring> ...]   (no substring = all)"""
import os, sys, time
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
sys.path.insert(0, os.path.join(W, "tools"))
import taintset_scrub_guard as G
args = [a for a in sys.argv[1:] if a != "--no-pch"]
if "--no-pch" in sys.argv:
    G.USE_PCH = False
hdr, st, sc = open(G.HEADER).read(), open(G.SELFTEST).read(), open(G.SCRUB_HDR).read()
lp = open(os.path.join(G.INCLUDE_DIR, "LoopPlan.h")).read()
muts = [m for m in G._mutants(hdr, st, sc, lp) if not args or any(a in m[0] for a in args)]
t0 = time.time()
bad = 0
for m in muts:
    label, h, s, x, al, expect = m[:6]
    extra = m[6] if len(m) > 6 else None
    errs, n = G.check(h, s, al, x, extra_headers=extra)
    ok = (not errs) if expect is None else any(expect in e for e in errs)
    bad += not ok
    print(f"{'ok ' if ok else 'BAD'} expect={expect!r:22} {label}  [{n} members, {len(errs)} problems]")
    for e in errs[:3]:
        print("      " + e.splitlines()[0][:230])
print(f"{len(muts)} mutants, {bad} bad, {time.time() - t0:.1f}s, PCH {G._PCH['state']} USE_PCH={G.USE_PCH}")
if G._PCH["dir"]:
    import shutil
    shutil.rmtree(G._PCH["dir"], ignore_errors=True)
sys.exit(1 if bad else 0)
