#!/usr/bin/env python3
"""Build the stage-1 (.ll) corpus of every run_slice.sh / run_slice_multi.sh
ctest entry, with the SAME clang / llvm-link commands the harness uses, parsed
from `ctest -N -V`. Output: $T/e2e_s1/<testname>.ll (single) and
$T/e2e_multi_s1/<testname>.ll (multi-TU)."""
import os, re, shlex, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"
T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r"
out = subprocess.run(["ctest", "--test-dir", f"{W}/build", "-N", "-V"],
                     capture_output=True, text=True).stdout
single, multi = [], []
name = None
for line in out.splitlines():
    m = re.match(r"^\s*Test\s+#\d+:\s+(\S+)", line)
    if m:
        name = m.group(1)
        continue
    m = re.match(r"^\d+: Test command: (.*)$", line)
    if not m or name is None:
        continue
    argv = shlex.split(m.group(1))
    if len(argv) > 1 and argv[1].endswith("/run_slice.sh"):
        a = argv[2:]
        single.append((name, a[0], a[3], a[4]))  # clang, inc, src
    elif len(argv) > 1 and argv[1].endswith("/run_slice_multi.sh"):
        a = argv[2:]
        multi.append((name, a[0], a[2], a[4], a[5], a[6]))  # clang, llvmlink, inc, cqsrc, libsrcs
    name = None

os.makedirs(f"{T}/e2e_s1", exist_ok=True)
os.makedirs(f"{T}/e2e_multi_s1", exist_ok=True)

def do_single(t):
    n, clang, inc, src = t
    o = f"{T}/e2e_s1/{n}.ll"
    r = subprocess.run([clang, f"-I{inc}", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", src, "-o", o],
                       capture_output=True)
    return (n, r.returncode)

def do_multi(t):
    n, clang, link, inc, cqsrc, libs = t
    d = f"{T}/e2e_multi_s1/{n}.parts"
    os.makedirs(d, exist_ok=True)
    ins = [f"{d}/cq.ll"]
    r = subprocess.run([clang, f"-I{inc}", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", cqsrc, "-o", ins[0]],
                       capture_output=True)
    if r.returncode:
        return (n, r.returncode)
    for i, lib in enumerate(libs.split()):
        li = f"{d}/lib_{i}.ll"
        r = subprocess.run([clang, f"-I{inc}", "-O1", "-emit-llvm", "-S", lib, "-o", li], capture_output=True)
        if r.returncode:
            return (n, r.returncode)
        ins.append(li)
    r = subprocess.run([link, "-S", *ins, "-o", f"{T}/e2e_multi_s1/{n}.ll"], capture_output=True)
    return (n, r.returncode)

with ThreadPoolExecutor(8) as ex:
    rs = list(ex.map(do_single, single)) + list(ex.map(do_multi, multi))
bad = [r for r in rs if r[1]]
print(f"single={len(single)} multi={len(multi)} failed={len(bad)} {bad[:5]}")
empty = [f for f in os.listdir(f"{T}/e2e_s1") if os.path.getsize(f"{T}/e2e_s1/{f}") == 0]
print("empty single outputs:", len(empty))
