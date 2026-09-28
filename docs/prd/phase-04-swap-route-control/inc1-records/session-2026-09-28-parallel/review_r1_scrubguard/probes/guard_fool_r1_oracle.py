#!/usr/bin/env python3
"""Review r1: the SAME probes against the ORACLE guard (main 9a230646, sha d26862662f12f1f5),
for INTRODUCED vs PRE-EXISTING. The oracle guard has no extra_headers (A6/A6b skipped: it
exempted allowlisted subtrees wholesale, r3 B14) and reads ONE compile command, so the
database is the subject's with its paths rewritten to the oracle worktree.
usage: CQ_GUARD_COMPILE_COMMANDS=<db> guard_fool_r1_oracle.py <oracle-root> <subject-root> id..."""
import os, sys, time
sys.dont_write_bytecode = True
ORC, SUBJ = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ORC, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G
import rv_mutations
st = open(G.SELFTEST).read() + '\nstatic void rv_touch(cq::TaintSet &T) { (void)T.RvScrubbed.size(); }\n'
sc = open(G.SCRUB_HDR).read()
want = set(sys.argv[3:])
P = [p for p in rv_mutations.build(ORC, G.EXTRA_INCLUDES) if p[0] in want and not p[4]]
for pid, label, kind, h, extra, _ in P:
    t1 = time.time()
    errs, n = G.check(h, st, G.ALLOWLIST, sc)
    print(f"{'CAUGHT' if errs else 'MISSED':8s} {pid:4s} {label} [oracle guard, {n} members, {len(errs)} problem(s), "
          f"USE_PCH={G.USE_PCH}, {time.time()-t1:.0f}s]", flush=True)
    for e in errs[:2]: print("        ERR  " + e.splitlines()[0][:230], flush=True)
import shutil
if G._PCH.get("dir"): shutil.rmtree(G._PCH["dir"], ignore_errors=True)
