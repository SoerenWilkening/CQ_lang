#!/usr/bin/env python3
"""Adversarial probes for bd xdu2.16: gates on the condition registers in the
positions a hoisted tree makes newly reachable. Usage: probes2.py OUTDIR OPT_A OPT_B [k=v...]"""
import os, subprocess, sys
sys.argv_copy = list(sys.argv)
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
L = "/usr/local/opt/llvm@19/bin"
out, OPTA, OPTB = sys.argv[1], sys.argv[2], sys.argv[3]
envb = dict(os.environ)
for kv in sys.argv[4:]:
    k, v = kv.split("=", 1); envb[k] = v
os.makedirs(out, exist_ok=True)
def mk(body, ret="cq_measure(q) + cq_measure(r) + cq_measure(a)"):
    return ("#include <stdlib.h>\n__attribute__((noinline)) static int slice(int n, int m) {\n"
            "    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;\n"
            f"    {body}\n    return {ret};\n}}\n"
            "int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }\n")
P = {
 # the tree is DEFINED before a rotation of a register it reads, then used in the loop
 "pre_rot_r":   mk("_Bool c = (q > 1) & (r < 5); r = cq_theta(r, 0.1); for (int i = 0; i < n; ++i) if (c) a += 3;"),
 "pre_rot_q":   mk("_Bool c = (q > 1) & (r < 5); q = cq_theta(q, 0.1); for (int i = 0; i < n; ++i) if (c) a += 3;"),
 "pre_rot_rz":  mk("_Bool c = (q > 1) & (r < 5); if (m > 3) cq_phi(0.2); for (int i = 0; i < n; ++i) if (c) a += 3;"),
 # the tree read in the loop and a rotation AFTER the loop on each register it reads (G-13)
 "post_rot_q":  mk("for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; q = cq_theta(q, 0.7);"),
 "post_rot_r":  mk("for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; r = cq_theta(r, 0.7);"),
 "post_rot_qr": mk("for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; q = cq_theta(q, 0.7); r = cq_theta(r, 0.7);"),
 "post_rot_a":  mk("for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; a = cq_theta(a, 0.7);"),
 # rotation in the body BEFORE / AFTER the select on a condition register
 "body_rot_pre":  mk("for (int i = 0; i < n; ++i) { r = cq_theta(r, 0.1); if ((q > 1) & (r < 5)) a += 3; }"),
 "body_rot_post": mk("for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) a += 3; q = cq_theta(q, 0.1); }"),
 # the condition read AFTER the loop too (tree node escapes the loop)
 "tree_escape": mk("_Bool c = (q > 1) & (r < 5); for (int i = 0; i < n; ++i) if (c) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(c)"),
 # a measure of a condition register BEFORE the loop (yiid-adjacent)
 "pre_meas_q":  mk("int mq = cq_measure(q); for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3;", "mq + cq_measure(r) + cq_measure(a)"),
 # a derived hoisted rail that is ALSO read after the loop (ii-d's allUsersInside)
 "der_escape":  mk("int p = q * 3 + 1; for (int i = 0; i < n; ++i) if ((p > 4) & (r < 5)) a += 3;", "cq_measure(p) + cq_measure(r) + cq_measure(a)"),
 # the accumulator also read INSIDE the condition (clobber, SCOPING 3c)
 "clobber":     mk("for (int i = 0; i < n; ++i) if ((q > 1) & (a < 5)) a += 3;"),
 # a second loop reusing the same hoisted tree
 "two_loops":   mk("for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) a += 3; for (int i = 0; i < m; ++i) if ((q > 1) & (r < 5)) a += 5;"),
 # an in-body non-diagonal gate on an UNRELATED register between trips
 "unrelated_rot": mk("int u = cq_theta(2, 0.3); for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) a += 3; u = cq_theta(u, 0.2); } a += cq_measure(u);"),
 # nested loops with the tree hoisted out of both
 "nest":        mk("for (int j = 0; j < m; ++j) { int s = 0; for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? i : 55; s += cq_measure(t); } a += s; }"),
}
def run1(opt, s1, env):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", s1, "-o", s1 + ".s2"], capture_output=True, env=env)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    wrn = [l for l in p.stderr.decode(errors="replace").splitlines() if "warning:" in l]
    fp = ""
    if p.returncode == 0:
        q = subprocess.run(["python3", W + "/tools/free_pairing_check.py", s1 + ".s2"], capture_output=True)
        fp = q.stdout.decode().strip().splitlines()[-1].split("site(s): ")[-1] if q.stdout else q.stderr.decode()[:80]
        if wrn: fp += f" WARN{len(wrn)}"
    first = err[0].split(": ", 2)[-1] if err else ""
    return p.returncode, first, fp
for name, src in P.items():
    c = os.path.join(out, name + ".c"); open(c, "w").write(src)
    s1 = os.path.join(out, name + ".s1.ll")
    subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1], check=True)
    a = run1(OPTA, s1, dict(os.environ)); b = run1(OPTB, s1, envb)
    mark = "  " if a[0] == b[0] else "**"
    print(f"{mark}{name:14s} A rc={a[0]} {a[1][-62:]:62s} | B rc={b[0]} {b[1][-50:]} {b[2]}")
