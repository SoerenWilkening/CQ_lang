import sys
CONDS = {"and": "(q > 1) & (r < 5)", "single": "q > 1", "or": "(q > 1) | (r < 5)"}
TAILS = {"none": "", "w": "    w = cq_theta(w, 0.7);\n"}
VALS = {"wi": "(w + I)", "wm": "(w * 3 + I)"}
def gen(name, cond, val, tail, form):
    b = "{ int t = (" + cond + ") ? " + val + " : 55; s += cq_measure(t); }"
    if form == "for": body = "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    elif form == "dw": body = "    int i = 0; do " + b.replace("I", "i") + " while (++i < n);\n"
    else: body = "".join("    " + b.replace("I", str(k + 1)) + "\n" for k in range(3))
    if form != "unr": body = body.replace("(w + i)", "(w + i + 1)").replace("(w * 3 + i)", "(w * 3 + i + 1)")
    s = ("__attribute__((noinline)) static int slice(int n) {\n    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n"
         "    int w = cq_theta(2, 0.4);\n    int s = 0;\n" + body + tail +
         "    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;\n}\n"
         "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n")
    open(name + ".c", "w").write(s)
for cn, c in CONDS.items():
    for vn, v in VALS.items():
        for tn, t in TAILS.items():
            for f in ("for", "dw", "unr"):
                gen(f"{cn}_{vn}_{tn}_{f}", c, v, t, f)
