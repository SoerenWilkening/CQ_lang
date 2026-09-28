#!/usr/bin/env python3
"""Source-mutation validation of the mechanisms ADDED for review r1 (bd hdxo ehni ofvm ngfa
5ci2 s6ma). Each source mutant disables ONE mechanism by a textual edit of the guard's
source (the anchor is asserted to occur exactly once); the mutated source is loaded with
the REAL __file__ and run against the self-test entries that mechanism owns plus the
pristine null. KILLED = at least one target stops being refused for the right reason
(or, for N7, a database case stops failing closed). N0, a comment edit, runs FIRST over the
union of every target and must move NOTHING. usage: source_mutants_r2.py [N-id ...]"""
import os, sys, time, types, shutil
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
PATH = os.path.join(W, "tools", "taintset_scrub_guard.py")
SRC = open(PATH).read()

MUTANTS = [
    ("N0", "NULL: a comment edit",
     [("# the INSTANCE the build selects is walked", "# (null mutant)")], None),
    ("N1", "unnamed type accepted whatever record defines it (the r3 behaviour, F-R1-1)",
     [("            if _anon_key(node[1]) in self.anon_walked:", "            if True:")],
     ["r1 A1 ", "r1 A1b"]),
    ("N2", "cv / restrict after `*` no longer stripped (F-R1-2)",
     [('        n = re.sub(r"(?:(?<=\\s)|(?<=[*&]))(const|volatile|__restrict|restrict)$", "", n).rstrip()',
       '        n = re.sub(r"\\s+(const|volatile)$", "", n)')],
     ["r1 A2 ", "r1 A2b", "r1 A2'"]),
    ("N3", "scrub:: argument shapes not checked (F-R1-5)",
     [("            bad = _scrub_shape_problem(nm, args)", "            bad = None")], ["r1 A9"]),
    ("N4", "every identity lookup forces the instantiation (the r3 behaviour, F-R1-3)",
     [('if force else ""))', 'if True else ""))')],
     ["r1 A3 ", "r1 A3'"]),
    ("N5", "base verified by is_base_of alone (F-R1-6)",
     [('            cond += f" && std::is_same<typename {_spell(dq)}::{bshort}, {_spell(text)}>::value"',
       '            pass')],
     ["r1 A4 ", "r1 A4'", "r1 A4b ", "r1 A4b'"]),
    ("N6", "no include-order check (F-R1-4)",
     [("    if not W.errs and not use_pch:   # a clean verdict", "    if False:   # a clean verdict")],
     ["r1 A5 ", "r1 A5' "]),
    ("N7", "an unparsable database entry of this tree is skipped (F-R1-7)",
     [("            if where.startswith(root):", "            if False:")], "DB"),
    ("N8", "policy \"fields\": library-container arguments not made strict (F-R1-9)",
     [('                if strict_args and a[0] not in ("named", "tmpl", "lit"):',
       '                if False:')],
     ["r1 A6'"]),
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
    return m


def battery(G, subs):
    hdr, st, sc = open(G.HEADER).read(), open(G.SELFTEST).read(), open(G.SCRUB_HDR).read()
    lp = open(os.path.join(G.INCLUDE_DIR, "LoopPlan.h")).read()
    muts = G._mutants(hdr, st, sc, lp)
    pick = [m for m in muts if m[0] == "NULL: pristine tree" or any(m[0].startswith(s) for s in subs)]
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
    if targets == "DB":
        res = [(l, "fails closed" if "control" not in l else None, ok, [d]) for l, ok, d in G._db_cases()]
    else:
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
