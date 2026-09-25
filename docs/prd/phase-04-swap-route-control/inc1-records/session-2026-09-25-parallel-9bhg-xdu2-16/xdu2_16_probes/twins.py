#!/usr/bin/env python3
"""Rolled-vs-unrolled twin family for bd xdu2.16 + K-independence.
Each cell: a per-trip-measured 4.4 select over a (hoisted) compound condition.
Usage: twins.py OUTDIR OPT [k=v env...]"""
import os, subprocess, sys, re
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
out, OPT = sys.argv[1], sys.argv[2]
env = dict(os.environ)
for kv in sys.argv[3:]:
    k, v = kv.split("=", 1); env[k] = v
os.makedirs(out, exist_ok=True)
K = 3
QR = "    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n"
# name: (decls, cond using I, value using I, post-loop tail, returns)
CELLS = {
 "and":    (QR, "(q > 1) & (r < 5)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "or":     (QR, "(q > 1) | (r < 5)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "nested": (QR, "((q > 1) & (r < 5)) | (q < -3)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "xor":    (QR, "(q > 1) ^ (r < 5)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "loopvar":(QR, "(q > 1) & (r < I)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "bool":   ("    _Bool b = cq_theta((_Bool)0, 0.5);\n    int q = cq_theta(0, 0.25);\n", "b & (q > 1)", "I", "", "cq_measure(b) + cq_measure(q)"),
 "mixed":  ("    int q = cq_theta(0, 0.25);\n", "q && m == n", "I", "", "cq_measure(q)"),
 "mixedor":("    int q = cq_theta(0, 0.25);\n", "q || m == n", "I", "", "cq_measure(q)"),
 "mixedvar":("    int q = cq_theta(0, 0.25);\n", "q && I < m", "I", "", "cq_measure(q)"),
 "der":    (QR + "    int p = q * 3 + 1;\n", "(p > 4) & (r < 5)", "I", "", "cq_measure(q) + cq_measure(r)"),
 "fp":     ("    double q = cq_theta(0.0, 0.25);\n    int r = cq_theta(1, 0.5);\n", "(q > 1.0) & (r < 5)", "I", "", "(int)cq_measure(q) + cq_measure(r)"),
 "datarot":(QR, "(q > 1) & (r < 5)", "I", "", "cq_measure(q) + cq_measure(r)"),
}
def src(name, rolled):
    decls, cond, val, tail, ret = CELLS[name]
    body = ""
    if rolled:
        c = cond.replace("I", "i"); v = val.replace("I", "i")
        body = f"    for (int i = 0; i < n; ++i) {{\n        int t = ({c}) ? {v} : 55;\n"
        if name == "datarot":
            body += "        t = cq_theta(t, 0.7);\n"
        body += "        s += cq_measure(t);\n    }\n"
    else:
        for i in range(K):
            c = cond.replace("I", str(i)); v = val.replace("I", str(i))
            body += f"    {{ int t = ({c}) ? {v} : 55;\n"
            if name == "datarot":
                body += "      t = cq_theta(t, 0.7);\n"
            body += "      s += cq_measure(t); }\n"
    return ("#include <stdlib.h>\n__attribute__((noinline)) static int slice(int n, int m) {\n" + decls +
            "    int s = 0;\n" + body + tail + f"    return {ret} + s;\n}}\n"
            "int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 2); }\n")

def build(c, tag):
    b = c[:-2]
    s1, s2, exe = b + ".s1.ll", b + ".s2.ll", b + ".exe"
    subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1], check=True)
    p = subprocess.run([OPT, "-passes=cq-lowering", "-S", s1, "-o", s2], capture_output=True, env=env)
    if p.returncode:
        e = [l for l in p.stderr.decode().splitlines() if "error:" in l]
        return None, (e[0].split(": ", 2)[-1] if e else "rc=%d" % p.returncode)
    fp = subprocess.run(["python3", W + "/tools/free_pairing_check.py", s2], capture_output=True).stdout.decode().strip().splitlines()[-1]
    subprocess.run([L + "/clang", s2, W + "/build/runtime/libcq_templates.a", W + "/build/runtime/libcq_runtime.a", "-o", exe], check=True, capture_output=True)
    t = subprocess.run([exe], capture_output=True).stdout.decode()
    warn = [l for l in p.stderr.decode().splitlines() if "warning:" in l]
    return t, fp.split("site(s): ")[-1] + (" WARN:" + str(len(warn)) if warn else "")

for name in CELLS:
    rc = os.path.join(out, name + "_rolled.c"); uc = os.path.join(out, name + "_unrolled.c")
    open(rc, "w").write(src(name, True)); open(uc, "w").write(src(name, False))
    tr, ir = build(rc, "r"); tu, iu = build(uc, "u")
    if tr is None or tu is None:
        print(f"{name:9s} rolled: {'ok' if tr is not None else ir} | unrolled: {'ok' if tu is not None else iu}")
        continue
    same = "IDENTICAL" if tr == tu else "DIFFERENT"
    print(f"{name:9s} {same} rolled {tr.count(chr(10))} lines [{ir}] unrolled {tu.count(chr(10))} lines [{iu}]")
