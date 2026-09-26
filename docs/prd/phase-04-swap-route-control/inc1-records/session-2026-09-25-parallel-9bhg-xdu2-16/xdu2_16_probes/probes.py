#!/usr/bin/env python3
"""Probe family for bd xdu2.16: compile each C probe on two binaries (or env), report
exit/first-error/2b summary. Usage: probes.py OUTDIR OPT_A OPT_B [ENVB k=v ...]"""
import os, subprocess, sys
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
out, OPTA, OPTB = sys.argv[1], sys.argv[2], sys.argv[3]
envb = dict(os.environ)
for kv in sys.argv[4:]:
    k, v = kv.split("=", 1); envb[k] = v
os.makedirs(out, exist_ok=True)

HDR = "#include <stdlib.h>\nstatic const int tbl[8] = {3,1,4,1,5,9,2,6};\n"
def mk(decls, body, ret, sig="int n, int m", call="atoi(argv[1]), atoi(argv[2])"):
    return (HDR + f"__attribute__((noinline)) static int slice({sig}) {{\n    {decls}\n    {body}\n    return {ret};\n}}\n"
            f"int main(int argc, char **argv) {{ (void)argv; return slice({call}); }}\n")

QR = "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5);"
P = {
 # pure-quantum compound trees, hoisted
 "and":     mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "or":      mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) | (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "andand":  mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if (q > 1 && r < 5) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "nested":  mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if (((q > 1) & (r < 5)) | (q < -3)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "xor":     mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) ^ (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "samereg": mk("int q = cq_theta(0, 0.25); int a = 0;", "for (int i = 0; i < n; ++i) if (q > 1 && q < 5) a += 3;", "cq_measure(q) + cq_measure(a)"),
 "twosel":  mk(QR + " int a = 0, z = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) { a += 3; z -= 2; }", "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(z)"),
 "loopvar": mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) & (r < i)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "permeas": mk(QR + " int s = 0;", "for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? i : 5; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + s"),
 # mixed classical leaf (xdu2.13 literal)
 "mixed":   mk("int q = cq_theta(0, 0.25); int a = 0;", "for (int i = 0; i < n; ++i) if (q && m == n) a += 3;", "cq_measure(q) + cq_measure(a)"),
 "mixedor": mk("int q = cq_theta(0, 0.25); int a = 0;", "for (int i = 0; i < n; ++i) if (q || m == n) a += 3;", "cq_measure(q) + cq_measure(a)"),
 "mixedvar":mk("int q = cq_theta(0, 0.25); int a = 0;", "for (int i = 0; i < n; ++i) if (q && i < m) a += 3;", "cq_measure(q) + cq_measure(a)"),
 "mixedtbl":mk("int q = cq_theta(0, 0.25); int a = 0, z = 0;", "for (int i = 0; i < n && i < 8; ++i) if (q && m == n) { a += tbl[i]; z -= tbl[i]; }", "cq_measure(q) + cq_measure(a) + cq_measure(z)"),
 # neighbours
 "treedata":  mk(QR + " int a = 0, s = 0;", "for (int i = 0; i < n; ++i) { _Bool f = (q > 1) & (r < 5); if (f) a += 3; s += cq_measure(f); }", "cq_measure(q) + cq_measure(r) + cq_measure(a) + s"),
 "treepost":  mk(QR + " int a = 0;", "_Bool f = (q > 1) & (r < 5); for (int i = 0; i < n; ++i) if (f) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(f)"),
 "rotcond":   mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; q = cq_theta(q, 0.3);", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "rotdata":   mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; a = cq_theta(a, 0.7);", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "rotinbody": mk(QR + " int a = 0;", "for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) a += 3; r = cq_theta(r, 0.1); }", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "boolleaf":  mk("_Bool b = cq_theta((_Bool)0, 0.5); int q = cq_theta(0, 0.25); int a = 0;", "for (int i = 0; i < n; ++i) if (b & (q > 1)) a += 3;", "cq_measure(b) + cq_measure(q) + cq_measure(a)"),
 "dersel":    mk(QR + " int a = 0;", "int p = q * 3; for (int i = 0; i < n; ++i) if ((p > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "derpost":   mk(QR + " int a = 0;", "int p = q * 3; for (int i = 0; i < n; ++i) if ((p > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(p)"),
 "nest2":     mk(QR + " int a = 0;", "for (int j = 0; j < m; ++j) for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "fp":        mk("double q = cq_theta(0.0, 0.25); int r = cq_theta(1, 0.5); int a = 0;", "for (int i = 0; i < n; ++i) if ((q > 1.0) & (r < 5)) a += 3;", "(int)cq_measure(q) + cq_measure(r) + cq_measure(a)"),
 "phase":     mk(QR, "for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) cq_phi(0.5);", "cq_measure(q) + cq_measure(r)"),
}

def run1(opt, s1, env):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", s1, "-o", s1 + ".s2"], capture_output=True, env=env)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l or "warning:" in l]
    fp = ""
    if p.returncode == 0:
        q = subprocess.run(["python3", W + "/tools/free_pairing_check.py", s1 + ".s2"], capture_output=True)
        fp = q.stdout.decode().strip().splitlines()[-1].split("site(s): ")[-1] if q.stdout else q.stderr.decode()[:80]
    first = err[0].split(": ", 2)[-1] if err else ""
    return p.returncode, first, fp

for name, src in P.items():
    c = os.path.join(out, name + ".c"); open(c, "w").write(src)
    s1 = os.path.join(out, name + ".s1.ll")
    subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1], check=True)
    a = run1(OPTA, s1, dict(os.environ)); b = run1(OPTB, s1, envb)
    mark = "  " if a[0] == b[0] else "**"
    print(f"{mark}{name:10s} A rc={a[0]} {a[1][-70:]:70s} | B rc={b[0]} {b[1][-60:]} {b[2]}")
