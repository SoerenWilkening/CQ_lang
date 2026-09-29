#!/usr/bin/env python3
"""Review r2: the probes that need extra headers (B1, B2, B7, B8), against the MAIN guard
(9a230646), whose check() takes no extra_headers: the extra files are written into the PRIVATE
main worktree's REAL ir-pass/include (check() copies it) and restored afterwards.
usage: CQ_GUARD_COMPILE_COMMANDS=<db> cmp_main_extra.py <main-worktree> id..."""
import os, sys, time
sys.dont_write_bytecode = True
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G, rv2_mutations
st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
inc = os.path.join(ROOT, "ir-pass", "include")
for pid, label, kind, h, extra, _u, _m in rv2_mutations.build(ROOT, G.EXTRA_INCLUDES):
    if pid not in sys.argv[2:]:
        continue
    saved = {}
    try:
        for f, t in (extra or {}).items():
            p = os.path.join(inc, f); saved[p] = open(p).read() if os.path.exists(p) else None
            open(p, "w").write(t)
        t1 = time.time(); errs, n = G.check(h, st, G.ALLOWLIST, sc)
        print(f"{'CAUGHT' if errs else 'MISSED':8s} {pid:4s} {label[:100]} [main guard, {n} members, {len(errs)} problem(s), {time.time()-t1:.0f}s]", flush=True)
        for e in errs[:2]: print("        ERR  " + e.splitlines()[0][:220], flush=True)
    finally:
        for p, t in saved.items():
            (open(p, "w").write(t) if t is not None else os.remove(p))
if G._PCH.get("dir"):
    import shutil; shutil.rmtree(G._PCH["dir"], ignore_errors=True)
