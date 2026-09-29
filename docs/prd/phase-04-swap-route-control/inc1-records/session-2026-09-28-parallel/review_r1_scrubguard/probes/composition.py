#!/usr/bin/env python3
"""Review r1: the subject guard (imported UNMODIFIED, gate semantics USE_PCH=False) run over the
TaintSet headers of the OTHER tracks of session 2026-09-28 that add a TaintSet member — their
ir-pass/include/*.h and their scrub_selftest.cpp, read-only from their worktrees.
usage: composition.py <subject-root> <other-worktree> ..."""
import os, subprocess, sys
sys.dont_write_bytecode = True
SUBJ = sys.argv[1]
sys.path.insert(0, os.path.join(SUBJ, "tools"))
import taintset_scrub_guard as G
G.USE_PCH = False
for wt in sys.argv[2:]:
    inc = os.path.join(wt, "ir-pass", "include")
    extra = {f: open(os.path.join(inc, f)).read() for f in os.listdir(inc) if f.endswith(".h")}
    hdr = extra.pop("TaintPropagation.h"); sc = extra.pop("ScrubOnDelete.h")
    st = open(os.path.join(wt, "ir-pass", "tools", "scrub_selftest.cpp")).read()
    head = subprocess.run(["git", "-C", wt, "log", "--oneline", "-1"], capture_output=True, text=True).stdout.strip()
    G._SPEC.clear(); G.LAST_RUN.clear()
    errs, n = G.check(hdr, st, G.ALLOWLIST, sc, extra_headers=extra)
    print(f"{'REFUSED' if errs else 'clean  '} {os.path.basename(wt)} @ {head[:90]}  [{n} members, {len(errs)} problem(s), passes={G.LAST_RUN.get('passes')}]", flush=True)
    for e in errs[:4]: print("        ERR  " + e.splitlines()[0][:240], flush=True)
