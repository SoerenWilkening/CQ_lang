__attribute__((noinline)) static int inc(int v) { return v - 1; }
int (*volatile vp)(int) = inc;
__attribute__((noinline)) static int f(int x, int (*cmp)(int)) { if (cmp(x) >= 0) return x + 1; return x; }
int q4a(int x0, double tx) { int x = x0; cq_theta(&x, tx); return cq_measure(f(x, vp)); }
int q4b(int x0, double tx) { int x = x0, r = 0; cq_theta(&x, tx); if (x & 1) r = f(x, vp); return cq_measure(r); }
__attribute__((noinline)) static int f2(int x, int (*cmp)(int)) { int s = 0; for (int i = 0; i < 3; i++) { if (cmp(x + i) >= 0) break; s += x; } return s; }
int q4c(int x0, double tx) { int x = x0, r = 0; cq_theta(&x, tx); if (x & 1) r = f2(x, vp); return cq_measure(r); }
int q4d(int x0, double tx) { int x = x0; cq_theta(&x, tx); return cq_measure(f2(x, vp)); }
