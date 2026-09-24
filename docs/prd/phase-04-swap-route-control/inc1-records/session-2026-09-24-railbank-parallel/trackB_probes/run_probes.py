#!/usr/bin/env python3
"""Run every probes/*.c through stage1 -> cq-opt -> (link, run, 2b) and print verdicts.

usage: run_probes.py WORKTREE [glob]
Prints one row per file and a pair verdict per bank/reg pair, with the denominator.
"""
import pathlib, subprocess, sys, tempfile, hashlib

WT = pathlib.Path(sys.argv[1])
GLOB = sys.argv[2] if len(sys.argv) > 2 else "*.c"
LLVM = "/usr/local/opt/llvm@19/bin"
import os
D = pathlib.Path(__file__).parent / os.environ.get("PROBES", "probes")
OPT = pathlib.Path(os.environ["CQOPT"]) if os.environ.get("CQOPT") else WT / "build/ir-pass/cq-opt"
PLUG = WT / "build/ir-pass/libCQPass.so"
RT = WT / "build/runtime/libcq_runtime.a"
TP = WT / "build/runtime/libcq_templates.a"


def run(cmd):
    return subprocess.run([str(c) for c in cmd], text=True, capture_output=True)


res = {}
tmp = pathlib.Path(tempfile.mkdtemp())
files = sorted(D.glob(GLOB))
for f in files:
    s1 = tmp / (f.stem + ".s1.ll")
    s2 = tmp / (f.stem + ".s2.ll")
    r = run([f"{LLVM}/clang", f"-I{WT}/include", "-include", "CQ.h", "-O1",
             "-emit-llvm", "-S", f, "-o", s1])
    if r.returncode:
        res[f.name] = ("CLANG-FAIL", r.stderr.strip().splitlines()[:1], None, "")
        continue
    txt = s1.read_text()
    if "define" not in txt or "@cq_" not in txt:
        res[f.name] = ("VACUOUS", [], None, "")
        continue
    r = run([OPT, "-load-pass-plugin", PLUG, "-passes=cq-lowering", "-S", s1, "-o", s2])
    if r.returncode:
        msg = [l for l in r.stderr.splitlines() if "error" in l][:1]
        res[f.name] = ("DECLINE", msg, None, "")
        continue
    exe = tmp / (f.stem + ".exe")
    lk = run([f"{LLVM}/clang", s2, TP, RT, "-o", exe])
    trace = run([exe, "3"]).stdout if lk.returncode == 0 else "LINKFAIL"
    fp = run(["python3", WT / "tools/free_pairing_check.py", s2])
    tail = (fp.stdout.strip().splitlines() or [""])[-1]
    bank = "!cq.railbank" in s2.read_text()
    res[f.name] = ("ACCEPT", [f"bank={bank} 2b[{tail}]"], trace, "")
    out = pathlib.Path(__file__).parent / os.environ.get("OUT", "out")
    out.mkdir(exist_ok=True)
    (out / (f.stem + ".trace")).write_text(trace)
    (out / (f.stem + ".s2.ll")).write_text(s2.read_text())
    (out / (f.stem + ".s1.ll")).write_text(s1.read_text())

for name, (v, msg, trace, _) in res.items():
    n = len(trace.splitlines()) if trace else 0
    print(f"{name:52s} {v:8s} {n:3d}L  {' '.join(m.strip() for m in msg)[:170]}")

print("--- pairs")
pairs = 0
for name in res:
    if name.endswith(".bank.c"):
        reg = name.replace(".bank.c", ".reg.c")
        if reg not in res:
            continue
        pairs += 1
        bv, rv = res[name][0], res[reg][0]
        if bv == "ACCEPT" and rv != "ACCEPT":
            verdict = "VIOLATION(bank accepts, reg declines)"
        elif bv != "ACCEPT" and rv == "ACCEPT":
            verdict = "over-decline"
        elif bv == rv == "ACCEPT":
            verdict = "ok-identical" if res[name][2] == res[reg][2] else "TRACE-MISMATCH"
        else:
            verdict = "ok-both-decline"
        print(f"{name.replace('.bank.c',''):48s} {verdict}")
print(f"files={len(files)} pairs={pairs}")
