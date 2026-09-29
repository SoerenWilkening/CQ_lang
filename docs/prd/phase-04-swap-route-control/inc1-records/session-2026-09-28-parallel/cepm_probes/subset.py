#!/usr/bin/env python3
"""subset.py OUT — the lit fixtures a mutant of `specCallResultPredictedClassical` can
possibly move: those that CALL a function DEFINED in the same module (outside the
reserved `cq_`/`__cq_`/`cqrt_` namespaces). The predicate returns false for every other
call (a declaration, an intrinsic, an indirect call), so a module with no such call is
byte-identical under every mutant of it — a sound superset filter, used to keep the
mutation matrix inside the load budget. (The null mutant, M1 and the 6.5 mutant M8 ran
over the whole corpus.)"""
import glob
import os
import re
import sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
out = []
for f in sorted(glob.glob(W + "/ir-pass/test/*.ll")):
    s = open(f, errors="replace").read()
    defs = set(re.findall(r"^define [^@]*@([\w.$]+)\(", s, re.M))
    defs = {d for d in defs if not d.startswith(("cq_", "__cq_", "cqrt_"))}
    calls = set(re.findall(r"call [^@\n]*@([\w.$]+)\(", s))
    if defs & calls:
        out.append(f)
open(sys.argv[1], "w").write("\n".join(out) + "\n")
print(len(out))
