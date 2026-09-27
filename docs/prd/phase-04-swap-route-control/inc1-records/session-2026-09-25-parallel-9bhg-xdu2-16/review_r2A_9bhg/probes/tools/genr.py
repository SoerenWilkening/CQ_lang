import pathlib
P = pathlib.Path(".")
H = "#include <stdlib.h>\n#include <stdbool.h>\nint h(int a, int k);\n"
F = "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = %s; return t; }\n"
LQ = "int h(int a, int k) { return a + k; }\n"; LC = "int h(int a, int k) { return k + 1; }\n"
B = {
 "rb1": "int x = f(m); bool bb[3]; for (int i = 0; i < 3; ++i) bb[i] = cq_theta((bool)((x >> i) & 1), .5); return cq_measure(bb[0]) + cq_measure(bb[1]) + cq_measure(bb[2]);",
 "rb2": "int x = f(m); int a = 5; bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; } return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a) + x;",
 "rb3": "int x = f(m); int q2 = cq_theta(n, .3); int r = q2 + x; int s = r > 7 ? 1 : 0; return cq_measure(s) + cq_measure(q2);",
 "rb4": "int x = f(m); int q2 = cq_theta(n, .3); if ((q2 > 3) && (x > 2)) cq_phi(.5); return cq_measure(q2);",
 "rb5": "int x = f(m); _Bool b = cq_theta((_Bool)(n & 1), .5); int p = b ? x : 4; return cq_measure(p) + cq_measure(b);",
 "rb6": "int x = f(m); int q2 = cq_theta(n, .3); int r = (q2 == x) ? 1 : 2; return cq_measure(r) + cq_measure(q2);",
}
for n, b in B.items():
    main = "int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); " + b + " }\n"
    for V, L in (("Q", LQ), ("C", LC)):
        (P/f"{n}{V}.c").write_text(H + F % "h(q, m)" + main); (P/f"{n}{V}.lib.c").write_text(L)
    (P/f"{n}T.c").write_text(H.replace("int h(int a, int k);\n", "") + F % "m + 1" + main)
