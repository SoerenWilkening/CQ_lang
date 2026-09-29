#!/usr/bin/env python3
"""Review r2: the SAME probes against an OLDER guard, for INTRODUCED vs PRE-EXISTING:
  - round 1 of the rewrite (223685ac, guard sha 99a7df7c) — did round 2 introduce or merely fail to close it?
  - main 9a230646 (the pre-rewrite guard, sha d2686266) — is it pre-existing on the tree's gate?
Each older guard runs from a PRIVATE worktree of its commit with the subject's database rewritten
to it (CQ_GUARD_COMPILE_COMMANDS). Probes are built from THAT worktree's headers (comment-only
differences). The main guard's check() takes no extra_headers, so probes that need them are skipped
there. Semantics: round 1 -> USE_PCH=False (its main()); main -> its own default, as review r1 did.
usage: CQ_GUARD_COMPILE_COMMANDS=<db> guard_fool_r2_cmp.py <guard-root> r1|main id..."""
import hashlib, inspect, os, sys, time
sys.dont_write_bytecode = True
ROOT, WHICH = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ROOT, "tools")); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import taintset_scrub_guard as G
import rv2_mutations
if WHICH == "r1":
    G.USE_PCH = False
has_extra = "extra_headers" in inspect.signature(G.check).parameters
st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
want = set(sys.argv[3:])
print(f"guard {G.__file__} sha256 {hashlib.sha256(open(G.__file__,'rb').read()).hexdigest()[:16]} USE_PCH={G.USE_PCH} "
      f"extra_headers={'yes' if has_extra else 'no'} db={G.COMPILE_COMMANDS}", flush=True)
for pid, label, kind, h, extra, _u, _m in rv2_mutations.build(ROOT, G.EXTRA_INCLUDES):
    if want and pid not in want:
        continue
    if extra and not has_extra:
        print(f"SKIPPED  {pid:4s} (needs extra_headers, which this guard's check() does not take)", flush=True)
        continue
    t1 = time.time()
    errs, n = G.check(h, st, G.ALLOWLIST, sc, extra_headers=extra) if has_extra else G.check(h, st, G.ALLOWLIST, sc)
    tag = ("CAUGHT" if errs else "MISSED") if kind == "attack" else (("ok " if (bool(errs) == (kind == "pos")) else "BAD") + kind)
    print(f"{tag:8s} {pid:4s} {label[:110]} [{n} members, {len(errs)} problem(s), {time.time()-t1:.0f}s]", flush=True)
    for e in errs[:2]: print("        ERR  " + e.splitlines()[0][:230], flush=True)
if getattr(G, "_PCH", None) and G._PCH.get("dir"):
    import shutil; shutil.rmtree(G._PCH["dir"], ignore_errors=True)
