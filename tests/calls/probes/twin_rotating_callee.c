__attribute__((noinline)) static int rot(int c) { int x = c; cq_theta(&x, 0.3); return x * 3; }
__attribute__((noinline)) static int f(int v, int c) { return rot(c) + v; }
__attribute__((noinline)) static int f2(int v, int c) { return f(v, c) * 5; }
__attribute__((noinline)) static void rv(int c) { int x = c; cq_theta(&x, 0.3); }
__attribute__((noinline)) static int f3(int v, int c) { rv(c); return v + 1; }
int y2a(int w0, double tw, int c0) { int w = w0, c = c0; cq_theta(&w, tw); cq_theta(&c, tw + 1); int r = f2(w, c); return cq_measure(r * r); }
int y2b(int w0, double tw, int c) { int w = w0; cq_theta(&w, tw); int r = f2(w, c); return cq_measure(r * r); }
int y2c(int w0, double tw, int c0) { int w = w0, c = c0; cq_theta(&w, tw); cq_theta(&c, tw + 1); int r = f3(w, c); return cq_measure(r * r); }
