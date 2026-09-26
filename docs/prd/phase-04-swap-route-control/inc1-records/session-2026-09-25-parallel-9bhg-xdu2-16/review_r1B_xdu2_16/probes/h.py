#!/usr/bin/env python3
"""Review r1B harness. h.py [--ll] FILE... : for each .c (or .ll with --ll) run
stage1 (clang -O1), stage2 on ORACLE and SUBJECT, 2b STRICT + CENSUS, link, run.
Prints one block per file. Traces saved next to the source as .{ora,sub}.trace."""
import os, subprocess, sys, hashlib
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
ORA = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main983"
SUB = W + "/build/ir-pass/cq-opt"
def stage1(c, extra=()):
    s1 = c[:-2] + ".s1.ll"
    p = subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", *extra, c, "-o", s1], capture_output=True, text=True)
    if p.returncode: raise SystemExit("stage1 failed " + c + p.stderr)
    if os.path.getsize(s1) == 0: raise SystemExit("EMPTY MODULE " + s1)
    return s1
def stage2(opt, s1, tag):
    s2 = s1.replace(".s1.ll", "") + f".{tag}.s2.ll"
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", s1, "-o", s2], capture_output=True, text=True)
    err = [l for l in p.stderr.splitlines() if "error:" in l]
    warn = [l for l in p.stderr.splitlines() if "warning:" in l]
    if p.returncode:
        msg = err[0].split(": ", 2)[-1] if err else f"rc={p.returncode} " + p.stderr[-200:]
        return dict(ok=False, msg=msg, warn=len(warn), rc=p.returncode)
    fp = subprocess.run(["python3", W + "/tools/free_pairing_check.py", s2], capture_output=True, text=True)
    fpl = fp.stdout.strip().splitlines()
    census = [l for l in fpl if "template rail" in l]
    exe = os.path.abspath(s2[:-3] + ".exe")
    lk = subprocess.run([L + "/clang", s2, W + "/build/runtime/libcq_templates.a", W + "/build/runtime/libcq_runtime.a", "-o", exe], capture_output=True, text=True)
    if lk.returncode: return dict(ok=False, msg="LINK FAIL " + lk.stderr[-300:], warn=len(warn), rc=99)
    t = subprocess.run([exe], capture_output=True, text=True).stdout
    open(s2[:-6] + ".trace", "w").write(t)
    lines = sum(1 for _ in open(s2))
    return dict(ok=True, fp=(fpl[-1] if fpl else "?"), fprc=fp.returncode, census=(census[-1] if census else ""), trace=t, warn=len(warn), lines=lines, warns=warn)
def show(tag, r):
    if not r["ok"]: return f"  {tag}: DECLINE [{r['msg'][:150]}]" + (f" warn={r['warn']}" if r['warn'] else "")
    return f"  {tag}: ACCEPT tr={r['trace'].count(chr(10))} ll={r['lines']} 2b(rc={r['fprc']})={r['fp'].split('site(s): ')[-1]} | {r['census'].strip()[:90]}" + (f" warn={r['warn']}" if r['warn'] else "")
if __name__ == "__main__":
    args = sys.argv[1:]
    ll = False
    if args and args[0] == "--ll": ll = True; args = args[1:]
    for f in args:
        s1 = f if ll else stage1(f)
        ro, rs = stage2(ORA, s1, "ora"), stage2(SUB, s1, "sub")
        print(os.path.basename(f)); print(show("ORA", ro)); print(show("SUB", rs))
        if ro["ok"] and rs["ok"]:
            print("  ORA-vs-SUB trace:", "IDENTICAL" if ro["trace"] == rs["trace"] else "DIFFERENT")
