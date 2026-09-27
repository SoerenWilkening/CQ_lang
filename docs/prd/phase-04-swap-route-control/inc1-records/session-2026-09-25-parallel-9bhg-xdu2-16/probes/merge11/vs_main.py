#!/usr/bin/env python3
"""Classify every alias-family module: FINAL merged (nofree reference, run twice as
its own null control) vs main aee8f4f8 (cq-opt.main_aee8, system allocator, run
twice). main is 8e5r-fixed and deterministic; the difference is exactly bd 9bhg.

Classes: IDENT (same exit + same lowered IR), BOTH-DECLINE (string may differ),
D->A (main declines, merged accepts: 9bhg's population), A->D (a regression unless
explained), STREAM (both accept, IR differs: the ordered scrub's population).
Writes merged/main lowered IR to <family>/<m>.{merged,main}.s2.ll for reading."""
import collections
import os
import pathlib
import subprocess
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
A = S / "alias9"
DBG = S / "frozen/cq-opt-debugalloc.final"
MAIN = S / "frozen/cq-opt.main_aee8"


def run(b, f, env_mode=None):
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None)
    if env_mode:
        env["CQ_OPT_DEBUG_ALLOC"] = env_mode
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True, env=env)
    err = next((l.split("error:", 1)[1].strip() for l in r.stderr.decode(errors="replace").splitlines()
                if "error:" in l), "")
    return r.returncode, r.stdout, err


def one(f):
    m1 = run(DBG, f, "nofree")
    m2 = run(DBG, f, "nofree")
    a1 = run(MAIN, f)
    a2 = run(MAIN, f)
    stem = f.with_suffix("").with_suffix("")
    f.with_name(stem.name + ".merged.s2.ll").write_bytes(m1[1])
    f.with_name(stem.name + ".main.s2.ll").write_bytes(a1[1])
    null_m = (m1[0], m1[1]) != (m2[0], m2[1])
    null_a = (a1[0], a1[1]) != (a2[0], a2[1])
    if a1[0] == 0 and m1[0] == 0:
        c = "IDENT" if a1[1] == m1[1] else "STREAM"
    elif a1[0] != 0 and m1[0] != 0:
        c = "BOTH-DECLINE"
    elif a1[0] != 0:
        c = "D->A"
    else:
        c = "A->D"
    return f.parent.name, stem.name, c, null_m, null_a, a1[2], m1[2]


files = sorted(A.glob("alias_gen*/*.s1.ll"))
with ThreadPoolExecutor(8) as ex:
    rows = list(ex.map(one, files))
print(f"modules: {len(rows)}")
print(f"null control merged (nofree twice): {sum(r[3] for r in rows)} of {len(rows)} differ")
print(f"null control main (sys twice):      {sum(r[4] for r in rows)} of {len(rows)} differ")
cnt = collections.Counter((r[0], r[2]) for r in rows)
for fam in sorted({r[0] for r in rows}):
    print(f"  {fam}: " + ", ".join(f"{c} {cnt[(fam, c)]}" for c in
                                   ("IDENT", "STREAM", "D->A", "A->D", "BOTH-DECLINE") if cnt[(fam, c)]))
for r in rows:
    if r[2] in ("STREAM", "D->A", "A->D"):
        print(f"  {r[2]:6} {r[0]}/{r[1]}  main=[{r[5][:100]}]  merged=[{r[6][:100]}]")
