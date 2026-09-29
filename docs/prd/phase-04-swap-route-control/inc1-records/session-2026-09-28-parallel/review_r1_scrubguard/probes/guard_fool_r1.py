#!/usr/bin/env python3
"""Review r1 (scrubguard): import the guard UNMODIFIED from the subject tree, call check()
with the GATE's own semantics (USE_PCH=False: every configuration, no PCH), controls first.
usage: guard_fool_r1.py <subject-root> [id ...]"""
import os, sys, time
sys.dont_write_bytecode = True
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G
import rv_mutations
G.USE_PCH = False            # what main() does: the gate's own verdict
st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
# A new self-cleaning member must be exercised by scrub_selftest.cpp (the guard checks the text);
# an agent adding one would add this line, so every probe gets it.
st = st + '\nstatic void rv_touch(cq::TaintSet &T) { (void)T.RvScrubbed.size(); }\n'
want = set(sys.argv[2:])
P = [p for p in rv_mutations.build(ROOT, G.EXTRA_INCLUDES) if not want or p[0] in want]
order = {"null": 0, "pos": 1, "attack": 2}
P.sort(key=lambda p: order[p[2]])
t0 = time.time(); bad, missed = [], []
for pid, label, kind, h, extra, _ in P:
    t1 = time.time()
    G.LAST_RUN.clear()
    errs, n = G.check(h, st, G.ALLOWLIST, sc, extra_headers=extra)
    tol = G.LAST_RUN.get("tolerated", [])
    passes = G.LAST_RUN.get("passes", [])
    if kind == "null":
        tag = "ok  null-clean" if not errs else "BAD null-refused"; (bad.append(pid) if errs else None)
    elif kind == "pos":
        tag = "ok  pos-refused" if errs else "BAD pos-clean"; (bad.append(pid) if not errs else None)
    else:
        tag = "CAUGHT" if errs else "MISSED"; (missed.append(pid) if not errs else None)
    print(f"{tag:18s} {pid:4s} {label}  [{n} members, {len(errs)} problem(s), {len(tol)} tolerated, "
          f"passes={passes}, {time.time()-t1:.0f}s]", flush=True)
    for e in errs[:3]: print("        ERR  " + e.splitlines()[0][:230], flush=True)
    new_tol = [t for t in tol if "Rv" in t]
    for t in new_tol[:3]: print("        NOTE " + t[:230], flush=True)
print(f"\ncontrols bad: {len(bad)} {bad}; attacks {sum(1 for p in P if p[2]=='attack')}, MISSED {len(missed)} {missed}")
print(f"elapsed {time.time()-t0:.0f}s; guard sha256 prefix: ", end="")
import hashlib; print(hashlib.sha256(open(G.__file__,'rb').read()).hexdigest()[:16])
