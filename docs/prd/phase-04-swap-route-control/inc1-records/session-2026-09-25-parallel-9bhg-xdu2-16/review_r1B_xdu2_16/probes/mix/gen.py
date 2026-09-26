BODIES = {
 "kick": "{ int t = ((q > 1) & (r < 5)) ? I : 55; if (w > 2) cq_phi(0.3); s += cq_measure(t); }",
 "kick2": "{ if (w > 2) cq_phi(0.3); int t = ((q > 1) & (r < 5)) ? I : 55; s += cq_measure(t); }",
 "kickd": "{ int t = ((q > 1) & (r < 5)) ? I : 55; int d = (t + w) > 7; if (w > 2) cq_phi(0.3); s += cq_measure(t) + cq_measure(d); }",
 "ry": "{ int t = ((q > 1) & (r < 5)) ? I : 55; int u = 3; if (w > 2) u = cq_theta(u, 0.4); s += cq_measure(t) + cq_measure(u); }",
 "call": "{ int t = ((q > 1) & (r < 5)) ? I : 55; if ((I & 1) == 1) s += g(I); s += cq_measure(t); }",
}
def gen(name, body, form):
    b = BODIES[body]
    if form == "for": L = "    for (int i = 0; i < n; ++i) " + b.replace("I", "i") + "\n"
    else: L = "".join("    " + b.replace("I", str(k)) + "\n" for k in range(3))
    s = ("__attribute__((noinline)) static int g(int k) { return k * k + 1; }\n"
         "__attribute__((noinline)) static int slice(int n) {\n    int q = cq_theta(0, 0.25);\n    int r = cq_theta(1, 0.5);\n"
         "    int w = cq_theta(2, 0.4);\n    int s = 0;\n" + L +
         "    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;\n}\n"
         "int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }\n")
    open(name + ".c", "w").write(s)
for bn in BODIES:
    for f in ("for", "unr"):
        gen(f"{bn}_{f}", bn, f)
