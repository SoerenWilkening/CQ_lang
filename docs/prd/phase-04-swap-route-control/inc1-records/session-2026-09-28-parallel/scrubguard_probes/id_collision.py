#!/usr/bin/env python3
"""Make source mutant S3 (walked-set key without the identity whose compile printed the
node) killable. clang's AST ids are heap addresses, ASLR-randomized per process, so two
identity compiles printing the SAME id for DIFFERENT records is possible but not
reproducible from C++ input. This harness FORCES it: `_identify` is wrapped so every record
node it returns carries one constant id. The guard must still refuse the mutant whose raw
member sits in the LAST of several project instances; S3 must miss it.
usage: id_collision.py"""
import os, sys, types
sys.dont_write_bytecode = True
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
PATH = os.path.join(W, "tools", "taintset_scrub_guard.py")
SRC = open(PATH).read()
S3 = ("    key = (W.cur_ident, rec.get(\"id\"), W.mode)", "    key = (rec.get(\"id\"), W.mode)")


def load(edits, tag):
    src = SRC
    for old, new in edits:
        assert src.count(old) == 1, tag
        src = src.replace(old, new, 1)
    m = types.ModuleType(f"guard_{tag}")
    m.__file__ = PATH
    exec(compile(src, PATH, "exec"), m.__dict__)
    orig = m._identify

    def colliding(ctx, qname, idx, retry=False, state=None):
        kind, payload, errs = orig(ctx, qname, idx, retry=retry, state=state)
        if kind == "record" and qname != m.ROOT_RECORD:
            payload = [dict(n, id="0xC011DE") for n in payload]
        return kind, payload, errs
    m._identify = colliding
    return m


for tag, edits in (("guard", []), ("S3", [S3])):
    G = load(edits, tag)
    G.USE_PCH = True
    hdr, st, sc = open(G.HEADER).read(), open(G.SELFTEST).read(), open(G.SCRUB_HDR).read()
    lp = open(os.path.join(G.INCLUDE_DIR, "LoopPlan.h")).read()
    muts = {m[0]: m for m in G._mutants(hdr, st, sc, lp)}
    for label in ("NULL: pristine tree",
                  "new: many project template INSTANCES identified in one round, one raw"):
        m = muts[label]
        errs, n = G.check(m[1], m[2], m[4], m[3])
        ok = (not errs) if m[5] is None else any(m[5] in e for e in errs)
        print(f"{tag:5} {'held ' if ok else 'MOVED'} expect={m[5]!r:15} {label}  [{n} members, {len(errs)} problems]"
              + (f"  -> {errs[0][:120]}" if errs else ""), flush=True)
    if G._PCH["dir"]:
        import shutil
        shutil.rmtree(G._PCH["dir"], ignore_errors=True)
