#!/usr/bin/env python3
"""twincheck.py REGEX: for every twin pair (merge12/twins.tsv) whose C tag matches
REGEX, lower both with cq-opt.m12 and compare: both decline -> DECL-SAME/-DIFF
(stderr), both accept -> TRACE-IDENT / DEAD-REG-ONLY / TRACE-DIFF (args 5 7, 2 9)."""
import difflib, pathlib, re, subprocess, sys
S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
H = S / "merge12"
C = H / "corp"
O = H / "tc"
O.mkdir(exist_ok=True)
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
B = S / "frozen/cq-opt.m12"
TPL, RT = W / "build/runtime/libcq_templates.a", W / "build/runtime/libcq_runtime.a"
pat = re.compile(sys.argv[1])


def lower(tag):
    s2 = O / f"{tag}.s2.ll"
    r = subprocess.run([str(B), "-passes=cq-lowering", "-S", str(C / f"{tag}.s1.ll"), "-o", str(s2)],
                       capture_output=True, text=True)
    if r.returncode:
        return r.returncode, r.stderr, None
    exe = O / f"{tag}.exe"
    subprocess.run([str(L / "clang"), "-Wno-everything", str(s2), str(TPL), str(RT), "-o", str(exe)],
                   capture_output=True)
    tr = []
    for a in (["5", "7"], ["2", "9"]):
        t = subprocess.run([str(exe)] + a, capture_output=True, text=True)
        tr.append(t.stdout.splitlines() + [f"exit={t.returncode}"])
    return 0, "", tr


for line in open(H / "twins.tsv"):
    c, t = line.rstrip("\n").split("\t")
    if not pat.search(c):
        continue
    a, b = lower(c), lower(t)
    if a[0] and b[0]:
        v = "DECL-SAME" if a[1] == b[1] else "DECL-DIFF"
    elif a[0] or b[0]:
        v = f"VERDICT-DIFF(C rc={a[0]}, T rc={b[0]})"
    elif a[2] == b[2]:
        v = "TRACE-IDENT"
    else:
        v = "DEAD-REG-ONLY"
        for x, y in zip(a[2], b[2]):
            d = [l for l in difflib.unified_diff(x, y, lineterm="", n=0)
                 if not l.startswith(("---", "+++", "@@"))]
            plus = [l[1:] for l in d if l.startswith("+")]
            if any(l.startswith("-") for l in d) or len(plus) % 2:
                v = "TRACE-DIFF"
                break
            for i in range(0, len(plus), 2):
                m = re.fullmatch(r"cqrt_ry_\w+\((h\d+), -0x[0-9a-fp.+-]+\)", plus[i])
                if not (m and plus[i + 1] == f"cqrt_free({m.group(1)})"):
                    v = "TRACE-DIFF"
    print(f"{c:50} {v}")
