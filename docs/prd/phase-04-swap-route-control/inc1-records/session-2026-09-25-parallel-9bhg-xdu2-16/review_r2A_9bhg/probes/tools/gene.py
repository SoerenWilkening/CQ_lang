import pathlib
P = pathlib.Path(".")
H = "#include <stdlib.h>\n#include <stdio.h>\nint h(int a, int k);\n"
LQ = "int h(int a, int k) { return a + k; }\n"; LC = "int h(int a, int k) { return k + 1; }\n"
FB = {
 "e1": "int r = (t > 3) ? 5 : 7; return r;",
 "e2": "int r = 7; if (t > 3) r = t + 2; return r;",
 "e3": "int r; switch (t) { case 6: r = 5; break; case 7: r = 9; break; default: r = 1; } return r;",
 "e4": "int r = 3; if (t > 5) { printf(\"%d\", t); r = 9; } return r;",
 "e5": "int r = t; if (t > 3) r = t + 1; return r;",
 "e6": "int r = t * 2; return r > 10 ? r : 10;",
 "e7": "int r = t; for (int i = 0; i < 3; i++) r = r + 1; return r;",
 "e8": "int r = 0; for (int i = 0; i < 3; i++) if (t > i) r = r + 1; return r;",
 "e9": "_Bool b = t & 1; return b ? 4 : 2;",
 "e10": "int r = t; if (m > 3) r = t + 1; return r;",
 "e11": "static const int T[8] = {3,1,4,1,5,9,2,6}; return T[t & 7];",
 "e12": "int a[4] = {0,0,0,0}; a[m & 3] = t; return a[(m+1) & 3] + a[m & 3];",
 "e13": "return t > 5;",
 "e14": "return (t > 5) + (t < 9);",
}
for n, b in FB.items():
    for V, L in (("Q", LQ), ("C", LC)):
        src = H + "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); " + b + " }\n" + \
              "int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }\n"
        (P/f"{n}{V}.c").write_text(src); (P/f"{n}{V}.lib.c").write_text(L)
    (P/f"{n}T.c").write_text(H.replace("int h(int a, int k);\n", "") + "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; " + b + " }\n" +
              "int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }\n")
print(len(FB))
