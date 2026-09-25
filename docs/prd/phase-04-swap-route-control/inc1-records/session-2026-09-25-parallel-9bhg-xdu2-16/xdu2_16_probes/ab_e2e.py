#!/usr/bin/env python3
"""e2e C-source A/B: every tests/e2e/*.c at its default CASE (and every CASE of the
matrix sources that declare `#define CASE_...` ids), stage 1 once, then OPT_A vs
OPT_B. Compares exit code, stdout sha, first error line. Usage: ab_e2e.py OPT_A OPT_B"""
import hashlib, os, re, subprocess, sys, glob, tempfile
from concurrent.futures import ThreadPoolExecutor
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
A, B = sys.argv[1], sys.argv[2]
T = tempfile.mkdtemp(prefix="x16e2e")
jobs = []
for c in sorted(glob.glob(W + "/tests/e2e/*.c")):
    src = open(c, errors="replace").read()
    cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
    if cases and "#ifndef CASE" in src:
        for k in cases:
            jobs.append((c, ["-DCASE=%d" % k]))
    else:
        jobs.append((c, []))
def run(opt, s1):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", s1], capture_output=True, timeout=300)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")
def one(j):
    c, d = j
    tag = os.path.basename(c) + ("" if not d else ":" + d[0][7:])
    s1 = os.path.join(T, tag.replace(":", "_") + ".s1.ll")
    p = subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S"] + d + [c, "-o", s1], capture_output=True)
    if p.returncode:
        return tag, None, None
    return tag, run(A, s1), run(B, s1)
with ThreadPoolExecutor(8) as ex:
    res = list(ex.map(one, jobs))
ok = [r for r in res if r[1] is not None]
print(f"denominator: {len(jobs)} (source, CASE) jobs; {len(ok)} compiled at stage 1; {len(jobs) - len(ok)} did not (need other TUs / flags) and were NOT swept")
mov = [(t, a, b) for t, a, b in ok if a != b]
print(f"movers {len(mov)} of {len(ok)}")
for t, a, b in mov:
    kind = ("D->A" if a[0] != 0 and b[0] == 0 else "A->D" if a[0] == 0 and b[0] != 0
            else "STRING" if a[0] != 0 else "STREAM")
    print(f"{kind}\t{t}\tA={a}\tB={b}")
