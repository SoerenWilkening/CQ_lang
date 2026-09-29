#!/usr/bin/env python3
"""fmt3 frontend A/B for the MULTI-TU e2e entries (the `run_slice_multi.sh` registrations in
tests/e2e/CMakeLists.txt, which ab_hdr.py cannot build on its own). For each entry: the CQ TU
is compiled `-include CQ.h -O1` against INC_A and INC_B, the lib TUs `-O1` WITHOUT CQ.h (exactly
as run_slice_multi.sh does), llvm-link, then the SAME cq-opt (frozen oracle by default).
Reports stage-1 movement of the CQ TU (normalised as ab_hdr.py does) and verdict/stream
movement of stage 2.  NULL CONTROL: INC_A == INC_B must move 0.
Usage: ab_hdr_multi.py INC_A INC_B [OPT]"""
import hashlib, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b"
L = "/usr/local/opt/llvm@19/bin"
ORA = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
       "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646")
INC_A, INC_B = sys.argv[1], sys.argv[2]
OPT = sys.argv[3] if len(sys.argv) > 3 else ORA
E2E = W + "/tests/e2e"
cm = open(E2E + "/CMakeLists.txt").read()
jobs = []
for m in re.finditer(r'add_test\(NAME\s+(\S+)\s+COMMAND\s+bash\s+"[^"]*run_slice_multi\.sh"(.*?)\)\s*$', cm, re.S | re.M):
    name, body = m.group(1), m.group(2)
    args = re.findall(r'"([^"]*)"', body)
    # CLANG OPT LLVMLINK PASS INC CQSRC LIBSRCS RT TPL GOLDEN [FLAGS]
    if len(args) < 10:
        print("UNPARSED", name, len(args)); continue
    sub = lambda s: s.replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E).replace("${CMAKE_SOURCE_DIR}", W)
    jobs.append((name, sub(args[5]), [sub(x) for x in args[6].split()]))
NORM = [(re.compile(r"^attributes #\d+ = .*$", re.M), ""), (re.compile(r" #\d+"), ""),
        (re.compile(r"\bnomerge\b ?"), ""), (re.compile(r"^; ModuleID = .*$", re.M), ""),
        (re.compile(r'^source_filename = .*$', re.M), "")]
def norm(b):
    s = b.decode(errors="replace") if isinstance(b, bytes) else b
    for rx, rep in NORM:
        s = rx.sub(rep, s)
    return "\n".join(l for l in s.splitlines() if l.strip())
sha = lambda s: hashlib.sha256(s.encode()).hexdigest()[:16]
T = tempfile.mkdtemp(prefix="fmt3multi")
def build(name, cq, libs, inc, tag):
    d = os.path.join(T, name + "." + tag); os.makedirs(d, exist_ok=True)
    r = subprocess.run([L + "/clang", "-I" + inc, "-include", "CQ.h", "-O1", "-emit-llvm", "-S", cq, "-o", d + "/cq.ll"], capture_output=True)
    if r.returncode: return None
    ins = [d + "/cq.ll"]
    for i, lib in enumerate(libs):
        o = f"{d}/lib_{i}.ll"
        r = subprocess.run([L + "/clang", "-I" + inc, "-O1", "-emit-llvm", "-S", lib, "-o", o], capture_output=True)
        if r.returncode: return None
        ins.append(o)
    r = subprocess.run([L + "/llvm-link", "-S"] + ins + ["-o", d + "/combined.ll"], capture_output=True)
    if r.returncode: return None
    p = subprocess.run([OPT, "-passes=cq-lowering", "-S", d + "/combined.ll"], capture_output=True, timeout=600)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (sha(norm(open(d + "/cq.ll").read())), (p.returncode, sha(norm(p.stdout)), err[0].split("error:", 1)[1].strip()[:140] if err else ""))
def one(j):
    name, cq, libs = j
    return name, build(name, cq, libs, INC_A, "A"), build(name, cq, libs, INC_B, "B")
with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, jobs))
ok = [r for r in res if r[1] and r[2]]
print(f"tmpdir {T}")
print(f"denominator: {len(jobs)} run_slice_multi.sh entries parsed; {len(ok)} built on BOTH headers; {len(jobs) - len(ok)} failed to build")
for n, a, b in res:
    if not (a and b): print("BUILDFAIL", n)
s1 = [(n, a, b) for n, a, b in ok if a[0] != b[0]]
v = [(n, a, b) for n, a, b in ok if a[1] != b[1]]
print(f"CQ-TU stage-1 movers (normalised): {len(s1)}; stage-2 verdict/stream movers: {len(v)}")
for n, a, b in s1: print("S1MOVE", n, a[1], b[1])
for n, a, b in v: print("VMOVE", n, a[1], b[1])
