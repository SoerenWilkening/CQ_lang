#!/usr/bin/env python3
"""z0re corpus A/B (derived from the 2026-09-25 xdu2_16_probes/ab.py + ab_e2e.py +
d88e_probes/multi_mods.py; ≤4 workers per the load discipline).

  ab.py OPT_A OPT_B MODE [MODE...]
  (OPT_B is run TWICE: the second run against the first is the NULL CONTROL,
   printed first and required to move 0; then OPT_A vs OPT_B.)
  MODE ∈ lit | e2e | multi | probes

  lit    — every ir-pass/test/*.ll
  e2e    — every tests/e2e/*.c at its default CASE (and every CASE of matrix sources),
           stage 1 = clang -O1 -include CQ.h
  multi  — every run_slice_multi.sh ctest entry, llvm-linked exactly as the harness does
  probes — every C source under the prior session's d88e / r1A / r1B probe dirs and this
           session's z0re_probes/src (a <b>C.c with a <b>C.lib.c is linked with it)

Compares (exit code, stdout sha-256[:16], first `error:` line). Prints the
denominator FIRST, then every mover with its class (D->A, A->D, STRING, STREAM).
Stage 1 (clang/llvm-link) is built ONCE, 4-way parallel, and shared by both
comparisons.
"""
import glob
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82"
L = "/usr/local/opt/llvm@19/bin"
PREV = W + "/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16"
HERE = os.path.dirname(os.path.abspath(__file__))
A, B = sys.argv[1], sys.argv[2]
MODES = sys.argv[3:]
T = tempfile.mkdtemp(prefix="z0re_ab_")


def run(opt, f):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", f], capture_output=True, timeout=600)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


def clang_cq(src, out, extra=()):
    return subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1",
                           "-emit-llvm", "-S", *extra, src, "-o", out],
                          capture_output=True).returncode == 0


def clang_lib(src, out):
    return subprocess.run([L + "/clang", "-I" + W + "/include", "-O1", "-emit-llvm", "-S",
                           src, "-o", out], capture_output=True).returncode == 0


def link(ins, out):
    return subprocess.run([L + "/llvm-link", "-S", *ins, "-o", out],
                          capture_output=True).returncode == 0


jobs = []  # (tag, path) or (tag, callable-returning-path-or-None)
for mode in MODES:
    if mode == "lit":
        for f in sorted(glob.glob(W + "/ir-pass/test/*.ll")):
            jobs.append(("lit:" + os.path.basename(f), f))
    elif mode == "e2e":
        for c in sorted(glob.glob(W + "/tests/e2e/*.c")):
            src = open(c, errors="replace").read()
            cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
            variants = ([["-DCASE=%d" % k] for k in cases]
                        if cases and "#ifndef CASE" in src else [[]])
            for d in variants:
                tag = "e2e:" + os.path.basename(c) + ("" if not d else ":" + d[0][7:])
                s1 = os.path.join(T, tag.replace(":", "_") + ".s1.ll")
                jobs.append((tag, (lambda c=c, s1=s1, d=d: s1 if clang_cq(c, s1, d) else None)))
    elif mode == "multi":
        E2E = W + "/tests/e2e"
        text = open(E2E + "/CMakeLists.txt").read()
        for m in re.finditer(r"add_test\(NAME\s+(\S+)\s+COMMAND\s+bash\s+\"\$\{CMAKE_CURRENT_SOURCE_DIR\}/run_slice_multi\.sh\"(.*?)\)\s*\n", text, re.S):
            name, args = m.group(1), m.group(2)
            toks = re.findall(r'"([^"]*)"', args)
            if len(toks) < 10:
                jobs.append(("multi:" + name, None))
                continue
            cq = toks[5].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E)
            libs = toks[6].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E).split()

            def mk(name=name, cq=cq, libs=libs):
                ins = [os.path.join(T, name + ".cq.ll")]
                ok = clang_cq(cq, ins[0])
                for i, lib in enumerate(libs):
                    p = os.path.join(T, f"{name}.lib{i}.ll")
                    ok = ok and clang_lib(lib, p)
                    ins.append(p)
                comb = os.path.join(T, name + ".multi.ll")
                ok = ok and link(ins, comb)
                return comb if ok else None
            jobs.append(("multi:" + name, mk))
    elif mode == "probes":
        dirs = [PREV + "/d88e_probes/src", PREV + "/review_r1A_d88e/probes/src",
                PREV + "/review_r1B_d88e/probes/src", HERE + "/src"]
        for d in dirs:
            for c in sorted(glob.glob(d + "/*.c")):
                if c.endswith(".lib.c"):
                    continue
                tag = "probe:" + os.path.relpath(c, W)

                def mk(c=c):
                    base = c[:-2]
                    key = re.sub(r"[^A-Za-z0-9]", "_", os.path.relpath(c, W))
                    s1 = os.path.join(T, key + ".cq.ll")
                    ok = clang_cq(c, s1)
                    if ok and os.path.exists(base + ".lib.c"):
                        lib = os.path.join(T, key + ".lib.ll")
                        comb = os.path.join(T, key + ".comb.ll")
                        ok = clang_lib(base + ".lib.c", lib) and link([s1, lib], comb)
                        s1 = comb
                    return s1 if ok else None
                jobs.append((tag, mk))
    else:
        sys.exit("unknown mode " + mode)

def materialise(tp):
    t, p = tp
    return t, (p() if callable(p) else p)


with ThreadPoolExecutor(4) as ex:
    jobs = list(ex.map(materialise, jobs))
ok = [(t, p) for t, p in jobs if p and os.path.getsize(p) > 0]
print(f"denominator: {len(jobs)} jobs; {len(ok)} runnable; {len(jobs) - len(ok)} not "
      f"(stage-1 failure / unparsed) and NOT swept   A={A}  B={B}", flush=True)
for t, p in jobs:
    if not (p and os.path.getsize(p) > 0):
        print(f"NOT-SWEPT\t{t}")


def one(tp):
    t, p = tp
    return t, run(B, p), run(B, p), run(A, p)


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, ok))


def report(title, pairs):
    mov = [(t, a, b) for t, a, b in pairs if a != b]
    nA = sum(1 for _, a, _ in pairs if a[0] == 0)
    nB = sum(1 for _, _, b in pairs if b[0] == 0)
    print(f"== {title}: accepts first={nA} second={nB}; movers {len(mov)} of {len(pairs)}")
    for t, a, b in mov:
        kind = ("D->A" if a[0] != 0 and b[0] == 0 else "A->D" if a[0] == 0 and b[0] != 0
                else "STRING" if a[0] != 0 else "STREAM")
        print(f"{kind}\t{t}\tA={a}\tB={b}")


report("NULL CONTROL (B vs B, must move 0)", [(t, b1, b2) for t, b1, b2, _ in res])
report("A/B (A vs B)", [(t, a, b1) for t, b1, _, a in res])
