#!/usr/bin/env python3
"""G-13 standing probe for bd xdu2.16: rolled-vs-unrolled with a trailing NON-DIAGONAL
gate on every register the condition reads (and on the data register). Both binaries.
Usage: g13.py OUTDIR ORACLE NEW"""
import os, subprocess, sys
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
out, ORA, NEW = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)
TAILS = {
 "q":  "    q = cq_theta(q, 0.7);\n",
 "r":  "    r = cq_theta(r, 0.7);\n",
 "qr": "    q = cq_theta(q, 0.7);\n    r = cq_theta(r, 0.7);\n",
 "none": "",
}
SHAPES = {
 # per-trip measured select (twinnable)
 "pertrip": ("    int s = 0;\n", "        { int t = ((q > 1) & (r < 5)) ? I : 55; s += cq_measure(t); }\n", "s"),
 # carried accumulator (row-13 flavour; the flat side folds/differs on trip 1, recorded)
 "acc":     ("    int a = 0;\n", "        if ((q > 1) & (r < 5)) a += 3;\n", "cq_measure(a)"),
}
def src(shape, tail, rolled):
    decl, body, res = SHAPES[shape]
    s = ("__attribute__((noinline)) static int slice(int n) {\n"
         "    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n" + decl)
    if rolled:
        s += "    for (int i = 0; i < n; ++i) {\n" + body.replace("I", "i") + "    }\n"
    else:
        for i in range(3):
            s += body.replace("I", str(i))
    s += TAILS[tail]
    s += f"    return cq_measure(q) + cq_measure(r) + {res};\n}}\n"
    s += "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n"
    return s
def run(opt, s1):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", s1, "-o", s1 + ".s2"], capture_output=True, text=True)
    e = [l for l in p.stderr.splitlines() if "error:" in l]
    w = [l for l in p.stderr.splitlines() if "warning:" in l]
    if p.returncode:
        return "DECLINE " + (e[0].split(": ", 2)[-1].split("lowering: ")[-1] if e else "?")
    exe = s1 + ".exe"
    subprocess.run([L + "/clang", "-x", "ir", s1 + ".s2", "-x", "none", W + "/build/runtime/libcq_templates.a", W + "/build/runtime/libcq_runtime.a", "-o", exe], check=True, capture_output=True)
    t = subprocess.run([exe], capture_output=True, text=True).stdout
    fp = subprocess.run(["python3", W + "/tools/free_pairing_check.py", s1 + ".s2"], capture_output=True, text=True).stdout.strip().splitlines()[-1].split("site(s): ")[-1]
    return f"ACCEPT {t.count(chr(10))} lines [{fp}]" + (f" WARN{len(w)}" if w else ""), t
for shape in SHAPES:
    for tail in TAILS:
        row = []
        for rolled in (True, False):
            c = os.path.join(out, f"{shape}_{tail}_{'rolled' if rolled else 'unrolled'}.c")
            open(c, "w").write(src(shape, tail, rolled))
            s1 = c[:-2] + ".s1.ll"
            subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1], check=True)
            row.append((run(ORA, s1), run(NEW, s1)))
        def fmt(x): return x if isinstance(x, str) else x[0]
        (ro, rn), (uo, un) = row
        ident = ""
        if not isinstance(rn, str) and not isinstance(un, str):
            ident = " TWIN=" + ("IDENTICAL" if rn[1] == un[1] else "DIFFERENT")
        print(f"{shape:8s} tail={tail:4s} ROLLED oracle: {fmt(ro)[:70]:70s} new: {fmt(rn)[:70]}")
        print(f"{'':8s} {'':9s} UNROLL oracle: {fmt(uo)[:70]:70s} new: {fmt(un)[:70]}{ident}")
