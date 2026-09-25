CONDS = {"and": "(q > 1) & (r < 5)", "single": "q > 1"}
BODIES = {
 "drot": "{ int t = (C) ? I : 55; int d = (t + r) > 7; t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }",
 "drot2": "{ int t = (C) ? I : 55; int d = (t * 3) > 7; t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }",
 "dmeas": "{ int t = (C) ? I : 55; int d = (t + r) > 7; s += cq_measure(t) + cq_measure(d); }",
 "wrot": "{ int t = (C) ? I : 55; int d = (w + t) > 7; w = cq_theta(w, 0.2); s += cq_measure(d); }",
 "tdrot": "{ int t = (C) ? I : 55; int d = (t ^ 3); t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }",
}
def gen(name, cond, body, form):
    b = BODIES[body].replace("C", cond)
    if form == "for": L = "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    elif form == "dw": L = "    int i = 0; do " + b.replace("I", "i") + " while (++i < n);\n"
    else: L = "".join("    " + b.replace("I", str(k)) + "\n" for k in range(3))
    s = ("__attribute__((noinline)) static int slice(int n) {\n    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n"
         "    int w = cq_theta(2, 0.4);\n    int s = 0;\n" + L +
         "    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;\n}\n"
         "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n")
    open(name + ".c", "w").write(s)
for cn, c in CONDS.items():
    for bn in BODIES:
        for f in ("for", "dw", "unr"):
            gen(f"{cn}_{bn}_{f}", c, bn, f)
