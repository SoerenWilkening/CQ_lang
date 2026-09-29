#!/usr/bin/env python3
"""Composition: THIS worktree's committed guard (imported unmodified, gate semantics
USE_PCH=False) run over the TaintSet headers of other worktrees of this session — their
ir-pass/include/*.h and their scrub_selftest.cpp, read-only (no git command is run; the
HEAD commit is read from the worktree's git metadata files).
usage: composition.py <other-worktree> ..."""
import os, sys
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
sys.path.insert(0, os.path.join(W, "tools"))
import hashlib
import taintset_scrub_guard as G
G.USE_PCH = False
G.set_jobs(int(os.environ.get("CQ_GUARD_JOBS", "3")))


def head_of(wt):
    try:
        gd = open(os.path.join(wt, ".git")).read().split("gitdir:", 1)[1].strip()
        h = open(os.path.join(gd, "HEAD")).read().strip()
        if h.startswith("ref:"):
            ref = h.split(None, 1)[1]
            common = open(os.path.join(gd, "commondir")).read().strip()
            base = os.path.normpath(os.path.join(gd, common))
            p = os.path.join(base, ref)
            if os.path.isfile(p):
                return ref + " @ " + open(p).read().strip()[:10]
            for line in open(os.path.join(base, "packed-refs")):
                if line.strip().endswith(ref):
                    return ref + " @ " + line.split()[0][:10]
            return ref
        return h[:10]
    except (OSError, IndexError):
        return "?"


print(f"guard {hashlib.sha256(open(G.__file__, 'rb').read()).hexdigest()[:16]}")
for wt in sys.argv[1:]:
    inc = os.path.join(wt, "ir-pass", "include")
    extra = {f: open(os.path.join(inc, f)).read() for f in os.listdir(inc) if f.endswith(".h")}
    hdr = extra.pop("TaintPropagation.h")
    sc = extra.pop("ScrubOnDelete.h")
    st = open(os.path.join(wt, "ir-pass", "tools", "scrub_selftest.cpp")).read()
    G._SPEC.clear()
    G.LAST_RUN.clear()
    errs, n = G.check(hdr, st, G.ALLOWLIST, sc, extra_headers=extra)
    print(f"{'REFUSED' if errs else 'clean  '} {os.path.basename(wt)} ({head_of(wt)})  [{n} members, "
          f"{len(errs)} problem(s), passes={G.LAST_RUN.get('passes')}, "
          f"{len(G.LAST_RUN.get('tolerated', []))} tolerated]", flush=True)
    for e in errs[:6]:
        print("        ERR  " + e.splitlines()[0][:240], flush=True)
if G._PCH["dir"]:
    import shutil
    shutil.rmtree(G._PCH["dir"], ignore_errors=True)
