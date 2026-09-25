import sys
D = "int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;"
R = "cq_measure(q) + cq_measure(r) + cq_measure(a)"
CELLS = {
 "a1": ("(q > 1) & (r < I + 5)", "a += 3"),
 "a2": ("(q > 1) & (r < I + 5)", "a += I + 1"),
 "a3": ("(q > 1) & (r < I + 5)", "a ^= (I + 1)"),
 "a4": ("(q > I) & (r < 5)", "a += 3"),
 "a5": ("(q > 1) & (r < 5)", "a += I + 1"),
 "a6": ("(q > 1) & (r < 5)", "a = a * 3 + I"),
}
for n, (c, u) in CELLS.items():
    body = "    for (int i = 0; i < n; ++i) { if (" + c.replace("I", "i") + ") " + u.replace("I", "i") + "; }\n"
    un = "".join("    { if (" + c.replace("I", str(k)) + ") " + u.replace("I", str(k)) + "; }\n" for k in range(3))
    for tag, b in (("rolled", body), ("unrolled", un)):
        open(f"acc/{n}_{tag}.c", "w").write("__attribute__((noinline)) static int slice(int n) {\n    " + D + "\n" + b +
            "    return " + R + ";\n}\nint main(void) { volatile int k = 3; return slice(k); }\n")
