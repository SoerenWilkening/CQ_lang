CONDS = {"and": "(q > 1) & (w < 5)", "lit": "(q > 1) & (m > 0)", "single": "q > 1"}
TY = {"i32": ("int", ""), "i8": ("signed char", "(signed char)")}
TAILS = {"none": "", "r": "    r = cq_theta(r, 0.7);\n"}
def gen(name, cond, ty, tail, form):
    T, cast = TY[ty]
    b = "{ int t = (" + cond + ") ? I : 55; int d = (r + I) > 3; s += cq_measure(t) + cq_measure(d); }"
    if form == "for": L = "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    elif form == "dw": L = "    int i = 0; do " + b.replace("I", "i") + " while (++i < n);\n"
    else: L = "".join("    " + b.replace("I", str(k)) + "\n" for k in range(3))
    s = ("__attribute__((noinline)) static int slice(int n, int m) {\n    int q = cq_theta(0, 0.25);\n"
         f"    {T} r = cq_theta({cast}1, 0.5);\n    int w = cq_theta(2, 0.4);\n    int s = 0;\n" + L + tail +
         "    return cq_measure(q) + (int)cq_measure(r) + cq_measure(w) + s;\n}\n"
         "int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }\n")
    open(name + ".c", "w").write(s)
for cn, c in CONDS.items():
    for ty in TY:
        for tn, t in TAILS.items():
            for f in ("for", "dw", "unr"):
                gen(f"{cn}_{ty}_{tn}_{f}", c, ty, t, f)
