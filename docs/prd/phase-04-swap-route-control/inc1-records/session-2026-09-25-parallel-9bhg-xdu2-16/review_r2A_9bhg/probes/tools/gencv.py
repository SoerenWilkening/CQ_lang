import pathlib
P = pathlib.Path(".")
H = "#include <stdlib.h>\n#include <stdio.h>\nint h(int a, int k);\n"
LIBS = {
 "cv1": "#include <stdio.h>\nint h(int a, int k) { int v = 3; if (a > 5) { printf(\"%d\", a); v = 7; } return v; }\n",
 "cv2": "int h(int a, int k) { return a > 3 ? 7 : 3; }\n",
 "cv4": "int h(int a, int k) { int r = k; for (int i = 0; i < 3; i++) if (a > i) r++; return r; }\n",
 "cv5": "int h(int a, int k) { switch (a) { case 1: return 5; case 2: return 9; default: return k; } }\n",
 "cv9": "int h(int a, int k) { volatile int z = a; return k + 1; }\n",
 "cv10": "int h(int a, int k) { int arr[4] = {1,2,3,4}; arr[a & 3] = 9; return arr[k & 3]; }\n",
 "cv11": "static const int T[4] = {1,2,3,4};\nint h(int a, int k) { return T[a & 3] * 0 + k; }\n",
 "cv12": "int g0(int x);\nint h(int a, int k) { return g0(a) * 0 + k + 1; }\nint g0(int x) { return x * 3; }\n",
 "cv13": "int h(int a, int k) { int r = k; if (a > 3) r = k + 1; return r; }\n",
 "cv14": "int h(int a, int k) { long long w = (long long)a * 0x100000000LL; return (int)(w >> 32) * 0 + (int)w + k; }\n",
 "cv15": "int h(int a, int k) { return (a >> 31) + k; }\n",
 "cv16": "int h(int a, int k) { return __builtin_popcount(a) * 0 + k; }\n",
 "cv17": "int h(int a, int k) { int s = 0; for (int i = 0; i < 4; i++) s += (a >> i) & 1; return s * 0 + k; }\n",
}
for n, lib in LIBS.items():
    # S: single-function (spec site in main) — pre-existing attribution
    (P/f"{n}S.c").write_text(H + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t) * 100 + cq_measure(q); }\n")
    (P/f"{n}S.lib.c").write_text(lib)
    # W: provisional wrapper (9bhg population)
    (P/f"{n}W.c").write_text(H + "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }\nint main(int c, char **v) { int m = atoi(v[1]); return cq_measure(f(m)) * 100 + 1; }\n")
    (P/f"{n}W.lib.c").write_text(lib)
print(len(LIBS))
EXTRA = {
 "cv20": "static const int T[8] = {3,1,4,1,5,9,2,6};\nint h(int a, int k) { return T[a & 7] + k; }\n",
 "cv21": "int h(int a, int k) { return (a > 3) + k; }\n",
 "cv22": "int h(int a, int k) { return a > k ? a : k; }\n",
 "cv23": "int h(int a, int k) { return __builtin_popcount(a) + k; }\n",
 "cv24": "int h(int a, int k) { return __builtin_ctz(a | 256) + k; }\n",
 "cv25": "int h(int a, int k) { unsigned u = a; return (int)(u % 7u) + k; }\n",
 "cv26": "int h(int a, int k) { return (a & 1) ? k + 1 : k + 2; }\n",
 "cv27": "int h(int a, int k) { long long w = a; return (int)((w * w) >> 40) + k; }\n",
}
for n, lib in EXTRA.items():
    (P/f"{n}S.c").write_text(H + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t) * 100 + cq_measure(q); }\n")
    (P/f"{n}S.lib.c").write_text(lib)
    (P/f"{n}W.c").write_text(H + "__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }\nint main(int c, char **v) { int m = atoi(v[1]); return cq_measure(f(m)) * 100 + 1; }\n")
    (P/f"{n}W.lib.c").write_text(lib)
