#!/usr/bin/env python3
"""Source-mutation validation of the NEW mechanisms of tools/taintset_scrub_guard.py
(bd wop9 / 7gri / jk56). Each source mutant disables ONE mechanism by a textual edit of
the guard's source (asserted to apply exactly once), is loaded as a fresh module with
the REAL __file__ (so ROOT/INCLUDE_DIR are the worktree's), and is run against the
self-test mutants that mechanism is responsible for, plus the pristine null. A source
mutant is KILLED when at least one of its targets stops being refused for the right
reason. S0 is the no-op null mutant (a comment edit): it must move NOTHING, and it is
run FIRST, over the union of every target.
usage: source_mutants.py [S-id ...]"""
import os, sys, time, types
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
PATH = os.path.join(W, "tools", "taintset_scrub_guard.py")
SRC = open(PATH).read()

MUTANTS = [
    ("S0", "NULL: a comment edit", [("# the INSTANCE the build selects is walked", "# (null mutant)")], None),
    ("S1", "spelling check dropped", [("    for path, text in spell_bad:", "    for path, text in []:")],
     ["AS-WRITTEN"]),
    ("S2", "no #undef of generated identifiers",
     [('    return [f"#undef {i}" for i in sorted(ids) if i not in _KEYWORDS]', "    return []")],
     ["macro defined AFTER"]),
    ("S3", "walked-key without the producing identity",
     [("    key = (W.cur_ident, rec.get(\"id\"), W.mode)", "    key = (rec.get(\"id\"), W.mode)")],
     ["many project template INSTANCES"]),
    ("S4", "KEY mode does not enter project records",
     [("    def _project(self, path, qname):\n",
       "    def _project(self, path, qname):\n        if self.mode == \"key\":\n            return\n")],
     ["r3 B7 ", "r3 B7'"]),
    ("S5", "allowlist exempts the whole subtree (the r3 behaviour)",
     [("            if p in W.allowlist and mode == \"strict\":\n                mode, origin = \"relaxed\", None",
       "            if p in W.allowlist and mode == \"strict\":\n                continue")],
     ["r3 B14"]),
    ("S6", "one configuration only (the first)",
     [("        _CFGS = cfgs\n", "        _CFGS = cfgs[:1]\n")], ["r3 B3 "]),
    ("S7", "no re-ask without the PCH",
     [("                passes = [(c, True) for c in cfgs] + [(c, False) for c in cfgs]",
       "                passes = [(c, True) for c in cfgs]")], ["r3 B4"]),
    ("S8", "a pointer to a LIBRARY template is not walked (the r3 behaviour)",
     [("        if k == \"tmpl\":\n            self._tmpl(path, inner)\n",
       "        if k == \"tmpl\":\n            if not _library(inner[1]):\n                self._tmpl(path, inner)\n")],
     ["r3 C1", "r3 C2", "r3 C3", "r3 C6"]),
]


def load(edits, tag):
    src = SRC
    for old, new in edits:
        assert src.count(old) == 1, f"{tag}: edit anchor found {src.count(old)} times: {old[:60]!r}"
        src = src.replace(old, new, 1)
    m = types.ModuleType(f"guard_{tag}")
    m.__file__ = PATH
    exec(compile(src, PATH, "exec"), m.__dict__)
    return m


def battery(G, subs):
    hdr, st, sc = open(G.HEADER).read(), open(G.SELFTEST).read(), open(G.SCRUB_HDR).read()
    lp = open(os.path.join(G.INCLUDE_DIR, "LoopPlan.h")).read()
    muts = G._mutants(hdr, st, sc, lp)
    pick = [m for m in muts if m[0] == "NULL: pristine tree" or any(s in m[0] for s in subs)]
    out = []
    for m in pick:
        label, h, s, x, al, expect = m[:6]
        errs, n = G.check(h, s, al, x, extra_headers=m[6] if len(m) > 6 else None)
        ok = (not errs) if expect is None else any(expect in e for e in errs)
        out.append((label, expect, ok, errs[:1]))
    return out


want = sys.argv[1:]
all_targets = sorted({t for _, _, _, ts in MUTANTS if ts for t in ts})
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
        tgt = [r for r in res if r[0] != "NULL: pristine tree"]
        killed = [r for r in tgt if not r[2]]
        ctl = [r for r in res if r[0] == "NULL: pristine tree"]
        verdict = (f"KILLED ({len(killed)}/{len(tgt)} targets flip)" if killed else "MISSED") + \
                  ("" if all(c[2] for c in ctl) else " [pristine control ALSO moved]")
    print(f"{sid} {desc}: {verdict}  [{len(res)} checks, {time.time() - t0:.0f}s]")
    for label, expect, ok, e in res:
        print(f"    {'held ' if ok else 'MOVED'} expect={expect!r:22} {label}" + (f"  -> {e[0][:140]}" if (not ok and e) else ""))
    if G._PCH["dir"]:
        import shutil
        shutil.rmtree(G._PCH["dir"], ignore_errors=True)
print(f"total {time.time() - t_all:.0f}s")
