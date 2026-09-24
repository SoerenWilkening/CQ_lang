#!/usr/bin/env python3
"""A/B the pre-fix cq-opt (cq-opt.base) against the worktree's cq-opt on every
ir-pass/test/*railbank*.ll fixture and every stage-1 module under out*/ .
Prints movers (rc change, or stdout change) and the denominator. A NULL CONTROL
(base vs base) runs first and must move 0."""
import pathlib, subprocess, sys
SP = pathlib.Path(__file__).parent
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
import os
BASE = SP / os.environ.get("BASE", "cq-opt.base")
NEW = WT / "build/ir-pass/cq-opt"
files = sorted((WT / "ir-pass/test").glob("*railbank*.ll"))
for d in ("out", "out2", "out3", "out4", "out5", "out7r2", "out7b", "out9", "out10", "out10r2"):
    files += sorted((SP / d).glob("*.s1.ll"))
files += sorted((SP / "s1all").glob("*.s1.ll"))


def run(opt, f):
    r = subprocess.run([str(opt), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def sweep(a, b, label):
    movers = []
    for f in files:
        ra, rb = run(a, f), run(b, f)
        if ra[0] != rb[0] or ra[1] != rb[1]:
            movers.append((f.name, ra[0], rb[0], (rb[2].strip().splitlines() or [""])[0][-110:]))
    print(f"{label}: {len(movers)} mover(s) of {len(files)}")
    for m in movers:
        print("  ", m)


sweep(BASE, BASE, "NULL (base vs base)")
sweep(BASE, NEW, "A/B (base vs new)")
