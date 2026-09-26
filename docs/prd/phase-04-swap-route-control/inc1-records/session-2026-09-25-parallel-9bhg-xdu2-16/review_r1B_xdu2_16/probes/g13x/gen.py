BODIES = {
 # in-body derived leaf in the select tree
 "xleaf": "{ int t = (((r ^ I) > 3) & (q > 1)) ? I : 55; s += cq_measure(t); }",
 # in-body derived data compare measured (value of d kept)
 "xdata": "{ int t = ((q > 1) & (w < 5)) ? I : 55; int d = (r ^ I) > 3; s += cq_measure(t) + cq_measure(d); }",
 # in-body xor rail read by a data compare zext'd into the select value
 "xval":  "{ int t = ((q > 1) & (w < 5)) ? ((r ^ I) > 3) : 55; s += cq_measure(t); }",
 # in-body xor rail consumed by a measure-less compare whose result feeds a second select's condition
 "xsel2": "{ int t = ((q > 1) & (w < 5)) ? I : 55; int u = ((r ^ I) > 3) ? 7 : 9; s += cq_measure(t) + cq_measure(u); }",
}
TAILS = {"none": "", "r": "    r = cq_theta(r, 0.7);\n"}
def gen(name, body, tail, form):
    b = BODIES[body]
    if form == "for": L = "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    elif form == "dw": L = "    int i = 0; do " + b.replace("I", "i") + " while (++i < n);\n"
    else: L = "".join("    " + b.replace("I", str(k + 1)) + "\n" for k in range(3))
    if form != "unr": L = L.replace("(r ^ i)", "(r ^ (i + 1))").replace("? i :", "? (i + 1) :")
    s = ("__attribute__((noinline)) static int slice(int n) {\n    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n"
         "    int w = cq_theta(2, 0.4);\n    int s = 0;\n" + L + tail +
         "    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;\n}\n"
         "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n")
    open(name + ".c", "w").write(s)
for bn in BODIES:
    for tn, t in TAILS.items():
        for f in ("for", "dw", "unr"):
            gen(f"{bn}_{tn}_{f}", bn, t, f)
