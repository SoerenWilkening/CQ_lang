#!/usr/bin/env python3
"""Source-mutation validation of the mechanisms ADDED in round 3 (review r2 of the rewrite:
bd hdxo 5ci2 ngfa s6ma). Each source mutant disables ONE mechanism by a textual edit of the
guard's source (the anchor is asserted to occur exactly once); the mutated source is loaded
with the REAL __file__ and run against the self-test entries that mechanism owns plus the
pristine null. KILLED = at least one target stops being refused for the right reason. N0, a
comment edit, runs FIRST over the union of every target and must move NOTHING. The F-R2-8
fail-closed rule is not here: it needs a misbehaving compiler, and is measured by the
reviewer's fail_open_r2.py. usage: source_mutants_r3.py [id ...]"""
import os, sys, time, types, shutil
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
PATH = os.path.join(W, "tools", "taintset_scrub_guard.py")
SRC = open(PATH).read()

MUTANTS = [
    ("P0", "NULL: a comment edit",
     [("# the INSTANCE the build selects is walked", "# (null mutant)")], None),
    ("P1", "unnamed-record use accepted whatever MODE the declarator was walked in (F-R2-1)",
     [("and MODE_RANK[dmode] >= MODE_RANK[umode]})", "and True})")],
     ["rv2 B1'"]),
    ("P2", "unnamed-record identity not asked of the compiler (F-R2-2)",
     [('cond = " || ".join(f"std::is_same<{core(uj.k)}, {core(dk)}>::value" for dk in cands)',
       'cond = "true"')],
     ["rv2 B4", "rv2 B5"]),
    ("P3", "a derived class's own member named like its base not refused (F-R2-3)",
     [("        if bshort in own_names:", "        if False:")],
     ["rv2 B3'"]),
    ("P4", "no token ban in closure files (F-R2-6)",
     [("        m = _CTX_TOKENS.search(_strip_comments(texts[f]))", "        m = None")],
     ["rv2 B9"]),
    ("P5", "no 'closure files included first' context (F-R2-5)",
     [('first = "".join(f\'#include "{f}"\\n\' for f in files if f in guards and f != "TaintPropagation.h")',
       'first = "".join(f\'#include "{f}"\\n\' for f in files if False)')],
     ["rv2 B11"]),
    ("P6", "closure restricted to top-level .h files (the round-2 regex closure, F-R2-4)",
     [("cur = os.path.relpath(f, tmp) if f.startswith(tmp + os.sep) else None",
       "cur = os.path.relpath(f, tmp) if f.startswith(tmp + os.sep) and f.endswith('.h') and "
       "os.sep not in os.path.relpath(f, tmp) else None")],
     ["rv2 D1", "rv2 D2"]),
    ("P7", "policy \"fields\": pointer arrays and pointer-to-pointers tolerated (F-R2-7)",
     [('is_arr or (node[0] == "ptr" and node[1][0] in ("ptr", "arr"))):', 'False):')],
     ["rv2 B2a", "rv2 B2b"]),
    ("P8", "policy \"fields\": records inside a library container keep the relaxed mode (F-R2-7)",
     [('if strict_args and not (root and a[0] in ("named", "lit")):',
       'if strict_args and not (a[0] in ("named", "tmpl", "lit")):')],
     ["rv2 B2c"]),
]


def load(edits, tag):
    src = SRC
    for old, new in edits:
        assert src.count(old) == 1, f"{tag}: anchor found {src.count(old)} times: {old[:70]!r}"
        src = src.replace(old, new, 1)
    m = types.ModuleType(f"guard_{tag}")
    m.__file__ = PATH
    exec(compile(src, PATH, "exec"), m.__dict__)
    m.set_jobs(int(os.environ.get("CQ_GUARD_JOBS", "3")))
    m.USE_PCH = False   # the gate's semantics (every pass runs the include-order check)
    return m


def battery(G, subs):
    hdr, st, sc = open(G.HEADER).read(), open(G.SELFTEST).read(), open(G.SCRUB_HDR).read()
    lp = open(os.path.join(G.INCLUDE_DIR, "LoopPlan.h")).read()
    muts = G._mutants(hdr, st, sc, lp)
    pick = [m for m in muts if m[0] == "NULL: pristine tree" or any(m[0].startswith(t) for t in subs)]
    out = []
    for m in pick:
        label, h, s, x, al, expect = m[:6]
        errs, n = G.check(h, s, al, x, extra_headers=m[6] if len(m) > 6 else None)
        ok = (not errs) if expect is None else any(expect in e for e in errs)
        out.append((label, expect, ok, errs[:1]))
    return out


want = sys.argv[1:]
all_targets = sorted({t for _, _, _, ts in MUTANTS if isinstance(ts, list) for t in ts})
t_all = time.time()
for sid, desc, edits, targets in MUTANTS:
    if want and sid not in want:
        continue
    t0 = time.time()
    G = load(edits, sid)
    res = battery(G, all_targets if targets is None else targets)
    moved = [r for r in res if not r[2]]
    if targets is None:
        verdict = "NULL OK (0 moved)" if not moved else f"NULL BROKEN ({len(moved)} moved)"
    else:
        ctl = [r for r in res if r[1] is None]
        tgt = [r for r in res if r[1] is not None]
        killed = [r for r in tgt if not r[2]]
        verdict = (f"KILLED ({len(killed)}/{len(tgt)} targets flip)" if killed else "MISSED") + \
                  ("" if all(c[2] for c in ctl) else " [a control ALSO moved]")
    print(f"{sid} {desc}: {verdict}  [{len(res)} checks, {time.time() - t0:.0f}s]", flush=True)
    for label, expect, ok, e in res:
        print(f"    {'held ' if ok else 'MOVED'} expect={expect!r:28} {label[:110]}"
              + (f"  -> {str(e[0])[:130]}" if (not ok and e) else ""), flush=True)
    if G._PCH["dir"]:
        shutil.rmtree(G._PCH["dir"], ignore_errors=True)
print(f"total {time.time() - t_all:.0f}s")
