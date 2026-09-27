import pathlib
P = pathlib.Path(".")
H = "#include <stdlib.h>\n#include <stdbool.h>\nint h(int a, int k);\n"
F = "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = %s; return t; }\n"
LQ = "int h(int a, int k) { return a + k; }\n"; LC = "int h(int a, int k) { return k + 1; }\n"
B = {
 "ln1": "int a = f(m); bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; } return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);",
 "ln2": "int a = 5; int k = f(m); bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= k; } return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);",
 "ln3": "int a = 5; int k = f(m); bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= k) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; } return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);",
 "ln4": "int a = 5; int K = f(m) & 3; bool b0[4]; for (int i = 0; i < K; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; } return cq_measure(b0[0]) + cq_measure(a);",
 "ln5": "int q2 = cq_theta(n, .3); int r = f(m); for (int i = 0; i < 3; i++) { if (q2 > i) cq_phi(r * .1); } return cq_measure(q2);",
 "ln6": "int q2 = cq_theta(n, .3); int k = f(m); for (int i = 0; i < 3; i++) { q2 = cq_theta(q2, k * .1); } return cq_measure(q2);",
}
for n, b in B.items():
    main = "int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); " + b + " }\n"
    for V, L in (("Q", LQ), ("C", LC)):
        (P/f"{n}{V}.c").write_text(H + F % "h(q, m)" + main); (P/f"{n}{V}.lib.c").write_text(L)
    (P/f"{n}T.c").write_text(H.replace("int h(int a, int k);\n", "") + F % "m + 1" + main)
