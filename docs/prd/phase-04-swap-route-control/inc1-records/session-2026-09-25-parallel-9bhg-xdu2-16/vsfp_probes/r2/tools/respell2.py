#!/usr/bin/env python3
"""respell2.py FILE... : bd vsfp round 2 — turn round 1's DEAD READ
(`%vsfp.read = mul …`, which the liveness predicate now sees as dead) into a
BRANCH-ONLY READ (an empty diamond on the parameter), which the predicate — having
no control dependence — keeps LIVE in the original callee. Rewrites the header
note in place. Prints what it changed."""
import re
import sys

LINE = re.compile(r"^(  )%vsfp\.read = (f?mul) (\S+) (%[\w.]+), \S+   ; bd vsfp: a DEAD READ keeps this parameter used$")


def zero(ty):
    if ty == "x86_fp80":
        return "0xK00000000000000000000"
    if ty in ("float", "double", "half", "fp128"):
        return "0.000000e+00"
    return "0"


for f in sys.argv[1:]:
    lines = open(f).read().split("\n")
    out = []
    n = 0
    for l in lines:
        m = LINE.match(l)
        if not m:
            out.append(l)
            continue
        ind, op, ty, p = m.groups()
        cmp = f"fcmp oeq {ty} {p}, {zero(ty)}" if op == "fmul" else f"icmp eq {ty} {p}, {zero(ty)}"
        out += [
            f"  %vsfp.c = {cmp}   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE",
            "  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join",
            "vsfp.arm:",
            "  br label %vsfp.join",
            "vsfp.join:",
        ]
        n += 1
    s = "\n".join(out)
    s = re.sub(r"The ONE added line in `(@[\w.]+)`, `%vsfp\.read`, is a DEAD READ that keeps(\n; )(the)?",
               lambda m: f"The added lines in `{m.group(1)}` (`%vsfp.c` and an EMPTY diamond on it) are a\n; BRANCH-ONLY READ that keeps" + m.group(2) + (m.group(3) or ""), s)
    # round-2 addendum after the note's CLAUDE.md L8 sentence (first occurrence)
    add = ("; ⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B): round 1's dead `mul` stopped keeping the\n"
           "; parameter used once the drop asked LIVENESS instead of `use_empty()` — a value that\n"
           "; reaches no root is dead. A branch condition IS a liveness root (the predicate has\n"
           "; no control dependence — `DeadValueLiveness.h` LIMITS), so this read keeps the\n"
           "; parameter live in the ORIGINAL callee; the clone's own flatten then removes it,\n"
           "; the specializer RECORDS the slot dead, and the operand here is a `cq_theta` result\n"
           "; (the backstop's one exemption) or the fixture says otherwise. A predicate WITH\n"
           "; control dependence (ADCE) retires this subject: the pin below turns red.\n;")
    if n and "ROUND 2 (bd vsfp, Rule-13 r1A/r1B)" not in s:
        s = s.replace("(CLAUDE.md L8).\n;\n", "(CLAUDE.md L8).\n" + add + "\n", 1)
    open(f, "w").write(s)
    print(f, n)
