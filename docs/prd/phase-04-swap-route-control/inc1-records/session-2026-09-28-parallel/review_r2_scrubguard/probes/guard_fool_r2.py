#!/usr/bin/env python3
"""Review r2 (scrubguard): import the guard UNMODIFIED from the subject tree, call check()
with the GATE's own semantics (USE_PCH=False: every configuration, no PCH, include-order check
on), controls first. Prints EVERY refusal (first line) and every tolerated note naming an Rv
member, so a battery probe can be attributed member by member.
usage: CQ_GUARD_JOBS=4 guard_fool_r2.py <subject-root> [id ...]"""
import hashlib, os, sys, time
sys.dont_write_bytecode = True
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G
import rv2_mutations
G.USE_PCH = False            # what main() does: the gate's own verdict
st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
want = set(sys.argv[2:])
P = [p for p in rv2_mutations.build(ROOT, G.EXTRA_INCLUDES) if not want or p[0] in want]
order = {"null": 0, "pos": 1, "attack": 2}
P.sort(key=lambda p: order[p[2]])
print(f"guard {G.__file__} sha256 {hashlib.sha256(open(G.__file__,'rb').read()).hexdigest()[:16]}; "
      f"JOBS={G.JOBS}; USE_PCH={G.USE_PCH}", flush=True)
t0 = time.time(); bad, missed = [], []
for pid, label, kind, h, extra, _u, _m in P:
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
    for e in errs: print("        ERR  " + e.splitlines()[0][:260], flush=True)
    for t in [t for t in tol if "Rv" in t]: print("        NOTE " + t[:260], flush=True)
print(f"\ncontrols bad: {len(bad)} {bad}; attacks {sum(1 for p in P if p[2]=='attack')}, MISSED {len(missed)} {missed}")
print(f"elapsed {time.time()-t0:.0f}s")
