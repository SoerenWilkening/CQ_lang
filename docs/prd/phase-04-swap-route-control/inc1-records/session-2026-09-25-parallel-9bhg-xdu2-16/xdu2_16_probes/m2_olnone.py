#!/usr/bin/env python3
"""Does r1B's (iii-b) repro (outleaf/ol_*.c) distinguish mutant M2 ("ignore totality")?
Stage 1 once; run BASE, then build M2, run, restore, rebuild, assert the restored hash."""
import hashlib, os, subprocess, sys
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
SRC = W + "/ir-pass/src/LoopLowering.cpp"
OPT = W + "/build/ir-pass/cq-opt"
P = W + "/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r1B_xdu2_16/probes/outleaf"
T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/x16/m2"
os.makedirs(T, exist_ok=True)
A_IRR = ("        if (!invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Fresh,\n"
         "                                    /*CarriedRoots=*/nullptr)) {\n")
M2 = A_IRR.replace("nullptr)) {", "nullptr)) && false) {").replace("if (!invariant", "if ((!invariant")
def h(): return hashlib.sha256(open(OPT, "rb").read()).hexdigest()[:16]
def build():
    p = subprocess.run(["cmake", "--build", W + "/build", "--target", "CQPass", "cq-opt", "-j8"], capture_output=True, text=True)
    assert p.returncode == 0, p.stdout[-2000:] + p.stderr[-2000:]
def run(tag):
    for c in sorted(os.listdir(P)):
        if not c.endswith(".c"): continue
        s1 = os.path.join(T, c[:-2] + ".s1.ll")
        if not os.path.exists(s1):
            subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", os.path.join(P, c), "-o", s1], check=True)
        p = subprocess.run([OPT, "-passes=cq-lowering", "-S", s1], capture_output=True, text=True)
        e = [l for l in p.stderr.splitlines() if "error:" in l]
        print(f"[{tag} {h()}] {c:14s} rc={p.returncode} out={hashlib.sha256(p.stdout.encode()).hexdigest()[:12]} {e[0].split('lowering: ')[-1] if e else ''}")
orig = open(SRC).read()
base = h()
assert orig.count(A_IRR) == 1
run("BASE")
try:
    open(SRC, "w").write(orig.replace(A_IRR, M2)); build(); run("M2")
finally:
    open(SRC, "w").write(orig); build()
print("restored", h(), "baseline", base, "OK" if h() == base else "MISMATCH")
