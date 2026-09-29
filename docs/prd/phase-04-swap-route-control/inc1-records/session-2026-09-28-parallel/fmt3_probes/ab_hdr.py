#!/usr/bin/env python3
"""fmt3 option (B) measurement: a FRONTEND A/B.  Every tests/e2e/*.c (every CASE of the
matrix sources, as xdu2_16_probes/ab_e2e.py does) is compiled at stage 1 TWICE — once
against INC_A/CQ.h and once against INC_B/CQ.h — and both stage-1 modules are run through
the SAME cq-opt (the frozen oracle by default).

Reported per job:
  S1   whether the stage-1 IR moved, after NORMALISING away what the header change alone
       produces (the `nomerge` token, attribute-group lines, `#N` attribute references)
  VERD exit code / normalised stdout sha / first error line of stage 2, A vs B

Usage: ab_hdr.py INC_A INC_B [OPT] [--list FILE] [-j N]
NULL CONTROL: run with INC_A == INC_B; it must report 0 S1 movers and 0 verdict movers."""
import hashlib, os, re, subprocess, sys, glob, tempfile
from concurrent.futures import ThreadPoolExecutor
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b"
L = "/usr/local/opt/llvm@19/bin"
ORA = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
       "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646")
args = [a for a in sys.argv[1:]]
J = 4
if "-j" in args:
    i = args.index("-j"); J = int(args[i + 1]); del args[i:i + 2]
srcs = None
if "--list" in args:
    i = args.index("--list"); srcs = [l.strip() for l in open(args[i + 1]) if l.strip()]; del args[i:i + 2]
INC_A, INC_B = args[0], args[1]
OPT = args[2] if len(args) > 2 else ORA
T = tempfile.mkdtemp(prefix="fmt3hdr")
jobs = []
for c in (srcs if srcs is not None else sorted(glob.glob(W + "/tests/e2e/*.c"))):
    src = open(c, errors="replace").read()
    cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
    if cases and "#ifndef CASE" in src:
        for k in cases:
            jobs.append((c, ["-DCASE=%d" % k]))
    else:
        jobs.append((c, []))

NORM = [(re.compile(r"^attributes #\d+ = .*$", re.M), ""),
        (re.compile(r" #\d+"), ""),
        (re.compile(r"\bnomerge\b ?"), ""),
        (re.compile(r"^; ModuleID = .*$", re.M), ""),
        (re.compile(r'^source_filename = .*$', re.M), "")]
def norm(b):
    s = b.decode(errors="replace")
    for rx, rep in NORM:
        s = rx.sub(rep, s)
    # the header change adds one attribute GROUP line; after deleting the group lines
    # only the blank-line count differs, so blank lines are dropped too (measured).
    return "\n".join(l for l in s.splitlines() if l.strip())
def sha(s):
    return hashlib.sha256(s.encode()).hexdigest()[:16]
def stage2(s1):
    p = subprocess.run([OPT, "-passes=cq-lowering", "-S", s1], capture_output=True, timeout=600)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, sha(norm(p.stdout)),
            err[0].split("error:", 1)[1].strip()[:160] if err else "")
def one(j):
    c, d = j
    tag = os.path.basename(c) + ("" if not d else ":" + d[0][7:])
    out = {}
    for side, inc in (("A", INC_A), ("B", INC_B)):
        s1 = os.path.join(T, tag.replace(":", "_") + "." + side + ".s1.ll")
        p = subprocess.run([L + "/clang", "-I" + inc, "-include", "CQ.h", "-O1", "-emit-llvm", "-S"]
                           + d + [c, "-o", s1], capture_output=True)
        if p.returncode or os.path.getsize(s1) == 0:
            return tag, None
        out[side] = (sha(norm(open(s1, "rb").read())), stage2(s1), s1)
    return tag, out
with ThreadPoolExecutor(J) as ex:
    res = list(ex.map(one, jobs))
ok = [(t, o) for t, o in res if o is not None]
print(f"tmpdir {T}")
print(f"denominator: {len(jobs)} (source, CASE) jobs; {len(ok)} compiled at stage 1 on BOTH headers; "
      f"{len(jobs) - len(ok)} did not (need other TUs / flags) and were NOT swept")
s1mov = [(t, o) for t, o in ok if o["A"][0] != o["B"][0]]
print(f"stage-1 movers (normalised): {len(s1mov)} of {len(ok)}")
vmov = [(t, o) for t, o in ok if o["A"][1] != o["B"][1]]
print(f"stage-2 verdict/stream movers: {len(vmov)} of {len(ok)}")
for t, o in s1mov:
    a, b = o["A"][1], o["B"][1]
    kind = ("SAME" if a == b else "D->A" if a[0] != 0 and b[0] == 0 else "A->D" if a[0] == 0 and b[0] != 0
            else "STRING" if a[0] != 0 else "STREAM")
    print(f"S1MOVE\t{kind}\t{t}\tA={a}\tB={b}")
# A verdict/stream move WITHOUT a stage-1 move would be non-determinism (or a broken
# normaliser) — it must be 0, and is printed so it cannot hide.
for t, o in vmov:
    if o["A"][0] == o["B"][0] and o["A"][1] == o["B"][1]:
        continue
    if (t, o) not in s1mov:
        print(f"VMOVE-WITHOUT-S1MOVE\t{t}\tA={o['A'][1]}\tB={o['B'][1]}")
