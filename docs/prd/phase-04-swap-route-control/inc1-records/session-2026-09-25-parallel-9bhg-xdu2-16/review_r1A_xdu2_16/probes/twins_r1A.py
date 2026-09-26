#!/usr/bin/env python3
"""Reviewer r1A twin family: rolled (runtime trip via noinline + volatile in main)
vs hand-unrolled (no loop). Each cell = (decls, rolled_body(template with {I}),
post, ret, loops). BODY uses {I} for the IV. For nests: 'nest' cells give
outer/inner explicitly. Prints per cell: ORA/SUBJ verdict for rolled, unrolled,
and whether SUBJ rolled == SUBJ unrolled trace."""
import os, subprocess, sys, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
AB = os.path.join(HERE, "ab.sh")
K = 3
QR = "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;"
CELLS = {}
def cell(name, decls, body, ret, post=""):
    CELLS[name] = (decls, body, ret, post)
# 1-level cells: body is a statement using {I}
cell("acc_and", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;",
     "if ((q > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)")
cell("acc_or_xor", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;",
     "if (((q > 1) | (r < 5)) ^ (q < -2)) a += 5;", "cq_measure(q) + cq_measure(r) + cq_measure(a)")
cell("two_trees", QR, "{ int t = ((q > 1) & (r < 5)) ? {I} : 55; int u = ((q < 3) | (r > 2)) ? 9 : {I}; s += cq_measure(t) + cq_measure(u); }",
     "cq_measure(q) + cq_measure(r) + s")
cell("preloop_sel_leaf", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0; int y = (q > 2) ? 3 : 9;",
     "{ int t = ((y > 4) & (r < 5)) ? {I} : 55; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + cq_measure(y) + s")
cell("preloop_sel_leaf_nomeas_y", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0; int y = (q > 2) ? 3 : 9;",
     "{ int t = ((y > 4) & (r < 5)) ? {I} : 55; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + s")
cell("bool_leaves", "_Bool b = cq_theta((_Bool)0, 0.5); _Bool c = cq_theta((_Bool)0, 0.7); int s = 0;",
     "{ int t = (b & c) ? {I} : 55; s += cq_measure(t); }", "cq_measure(b) + cq_measure(c) + s")
cell("bool_leaf_xor_cmp", "_Bool b = cq_theta((_Bool)0, 0.5); int q = cq_theta(0, 0.25); int s = 0;",
     "{ int t = (b ^ (q > 1)) ? {I} : 55; s += cq_measure(t); }", "cq_measure(b) + cq_measure(q) + s")
cell("carried_q_data", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;",
     "a = ((q > 1) & (r < 5)) ? a + q : a;", "cq_measure(q) + cq_measure(r) + cq_measure(a)")
cell("sel_value_is_leafreg", QR, "{ int t = ((q > 1) & (r < 5)) ? r : {I}; s += cq_measure(t); }",
     "cq_measure(q) + cq_measure(r) + s")
cell("sel_value_is_leafreg_derived", QR, "{ int t = ((q > 1) & (r < 5)) ? r + {I} : q; s += cq_measure(t); }",
     "cq_measure(q) + cq_measure(r) + s")
cell("hoisted_template_sel_value", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0; int p = q * 3;",
     "{ int t = ((q > 1) & (r < 5)) ? p : {I}; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + s")
cell("fp_leaf_or", "double d = cq_theta(0.0, 0.25); int r = cq_theta(1, 0.5); int s = 0;",
     "{ int t = ((d > 0.5) | (r == 1)) ? {I} : 55; s += cq_measure(t); }", "(int)cq_measure(d) + cq_measure(r) + s")
cell("i8_leaves", "signed char q = cq_theta((signed char)0, 0.25); short r = cq_theta((short)1, 0.5); int s = 0;",
     "{ int t = ((q > 1) & (r < 5)) ? {I} : 55; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + s")
cell("i8_sel", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;",
     "{ signed char t = ((q > 1) & (r < 5)) ? (signed char){I} : (signed char)-3; s += cq_measure(t); }", "cq_measure(q) + cq_measure(r) + s")
cell("dowhile_acc", "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;",
     "@DOWHILE if ((q > 1) & (r < 5)) a += 3;", "cq_measure(q) + cq_measure(r) + cq_measure(a)")

def gen(name, rolled):
    decls, body, ret, post = CELLS[name]
    dow = body.startswith("@DOWHILE ")
    body = body.replace("@DOWHILE ", "")
    if rolled:
        b = body.replace("{I}", "i")
        if dow:
            loop = "    int i = 0; do { " + b + " ++i; } while (i < n);\n"
        else:
            loop = "    for (int i = 0; i < n; ++i) { " + b + " }\n"
    else:
        loop = "".join("    { " + body.replace("{I}", str(k)) + " }\n" for k in range(K))
    return ("__attribute__((noinline)) static int slice(int n) {\n    " + decls + "\n" + loop + post +
            "    return " + ret + ";\n}\nint main(void) { volatile int k = %d; return slice(k); }\n" % K)

def run(c):
    p = subprocess.run([AB, c], capture_output=True, text=True, cwd=os.path.dirname(c))
    return p.stdout.strip().splitlines()

only = sys.argv[1:]
for name in CELLS:
    if only and name not in only: continue
    rc = os.path.join(HERE, "tw", name + "_rolled.c"); uc = os.path.join(HERE, "tw", name + "_unrolled.c")
    open(rc, "w").write(gen(name, True)); open(uc, "w").write(gen(name, False))
    rr = run(rc); ru = run(uc)
    def short(lines):
        out = []
        for l in lines:
            tag = l.split()[0]
            if "rc=0" in l:
                sha = l.split("sha=")[-1] if "sha=" in l else "?"
                tr = l.split("trace=")[-1].split()[0] if "trace=" in l else "?"
                vio = "2b-OK" if " 0 violation(s), 0 unproven" in l else "2b-BAD[" + l.split("2b:")[-1][:60] + "]"
                w = l.split("warn=")[1].split()[0]
                out.append(f"{tag}:A({tr},{sha},{vio},w{w})")
            else:
                out.append(f"{tag}:D[{l.split(':',3)[-1].strip()[:70]}]")
        return " ".join(out)
    sr = [l for l in rr if l.startswith("SUBJ")]; su = [l for l in ru if l.startswith("SUBJ")]
    ident = ""
    if sr and su and "sha=" in sr[0] and "sha=" in su[0]:
        ident = "IDENTICAL" if sr[0].split("sha=")[-1] == su[0].split("sha=")[-1] else "**DIFFERENT**"
    print(f"{name:28s} {ident:12s}\n   rolled:   {short(rr)}\n   unrolled: {short(ru)}")
