#!/usr/bin/env python3
"""Review r1B twin sweep: conditions x bodies x loop forms, rolled vs hand-unrolled
(K=3), both binaries. Prints per cell: rolled verdicts (ORA/SUB), unrolled verdicts,
twin identity on SUB, 2b, census. Usage: sweep.py OUTDIR [filter]"""
import os, sys, itertools
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import h
out = sys.argv[1]; flt = sys.argv[2] if len(sys.argv) > 2 else ""
os.makedirs(out, exist_ok=True)
DECL = {
 "i32": "    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n",
 "i8":  "    signed char q = cq_theta((signed char)0, 0.25);\n    signed char r = cq_theta((signed char)1, 0.5);\n",
 "i16": "    short q = cq_theta((short)0, 0.25);\n    short r = cq_theta((short)1, 0.5);\n",
 "i64": "    long long q = cq_theta(0LL, 0.25);\n    long long r = cq_theta(1LL, 0.5);\n",
 "bool":"    _Bool q = cq_theta((_Bool)0, 0.25);\n    int r = cq_theta(1, 0.5);\n",
}
CONDS = {
 "and": "(q > 1) & (r < 5)", "or": "(q > 1) | (r < 5)", "xor": "(q > 1) ^ (r < 5)",
 "nest": "((q > 1) & (r < 5)) | (q < -3)", "lit": "(q > 1) & (m > 0)",
 "litor": "(q > 1) | (m > 5)", "lvar": "(q > 1) & (r < I)", "der": "((q ^ m) > 1) & (r < 5)",
 "boolleaf": "q & (r < 5)", "boolor": "q | (r < 5)", "boollit": "q & (m > 0)",
}
BODIES = {
 "meas":   "{ int t = (C) ? I : 55; s += cq_measure(t); }",
 "rot":    "{ int t = (C) ? I : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }",
 "two":    "{ int t = (C) ? I : 55; int u = (C) ? 7 : I; s += cq_measure(t) + cq_measure(u); }",
 "dcmp":   "{ int t = (C) ? I : 55; int d = (r + I) > 3; s += cq_measure(t) + cq_measure(d); }",
 "valq":   "{ int t = (C) ? (q + I) : 55; s += cq_measure(t); }",
 "valqrot":"{ int t = (C) ? (q + I) : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }",
 "chain":  "{ int u = r * 3 + I; int t = (C) ? u : 55; s += cq_measure(t); }",
 "sel2":   "{ int t = (C) ? I : 55; int v = (t > 1) ? 3 : 4; s += cq_measure(v); }",
 "phase":  "{ int t = (C) ? I : 55; if (C) cq_phi(0.3); s += cq_measure(t); }",
 "rotr2":  "{ int t = (C) ? r : I; t = cq_theta(t, 0.7); s += cq_measure(t); }",
}
def src(decl, cond, body, form):
    b = BODIES[body].replace("C", CONDS[cond])
    s = "__attribute__((noinline)) static int slice(int n, int m) {\n" + DECL[decl] + "    int s = 0;\n"
    if form == "for":
        s += "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    elif form == "dw":
        s += "    int i = 0;\n    do " + b.replace("I", "i") + " while (++i < n);\n"
    else:
        for k in range(3): s += "    " + b.replace("I", str(k)) + "\n"
    s += "    return (int)cq_measure(q) + (int)cq_measure(r) + s;\n}\n"
    s += "int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }\n"
    return s
def v(r):
    if not r["ok"]: return "D:" + r["msg"].split("lowering: ")[-1][:48]
    return "A"
rows = []
for decl, cond, body in itertools.product(DECL, CONDS, BODIES):
    if decl == "bool":
        if not cond.startswith("bool"): continue
    elif cond.startswith("bool"): continue
    elif decl != "i32" and cond not in ("and", "lit"): continue
    name = f"{decl}_{cond}_{body}"
    if flt and flt not in name: continue
    res = {}
    for form in ("for", "dw", "unr"):
        c = os.path.join(out, f"{name}_{form}.c"); open(c, "w").write(src(decl, cond, body, form))
        try:
            s1 = h.stage1(c)
        except SystemExit as e:
            res[form] = None; continue
        res[form] = (h.stage2(h.ORA, s1, "ora"), h.stage2(h.SUB, s1, "sub"))
    line = [name]
    for form in ("for", "dw", "unr"):
        if res[form] is None: line.append(f"{form}=STAGE1FAIL"); continue
        o, n = res[form]
        line.append(f"{form}={v(o)}/{v(n)}")
    un = res["unr"][1] if res["unr"] else None
    for form in ("for", "dw"):
        if res[form] and res[form][1]["ok"]:
            n = res[form][1]
            extra = f" 2b[{n['fp'].split('site(s): ')[-1]}] cen[{n['census'].split('template rail mint(s) of which ')[-1].split(',')[0] if n['census'] else ''}]"
            if n["warn"]: extra += f" W{n['warn']}"
            if un and un["ok"]:
                extra += " TWIN=" + ("ID" if n["trace"] == un["trace"] else "DIFF")
            else:
                extra += " TWIN=unr-declines" + (" **ROLLED-ONLY**" if un else "")
            if not res[form][0]["ok"]: extra += " (new-accept)"
            else: extra += " oraSame=" + str(res[form][0]["trace"] == n["trace"])
            line.append(f"[{form}:{extra}]")
    print("  ".join(line), flush=True)
