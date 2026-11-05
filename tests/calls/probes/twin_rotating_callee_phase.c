__attribute__((noinline)) static int rot(int c) { int x = c; cq_theta(&x, 0.3); cq_phi(0.1); return x * 3; }
__attribute__((noinline)) static int f(int v, int c) { return rot(c) + v; }
int y3a(int w0, double tw, int c0) { int w = w0, c = c0; cq_theta(&w, tw); cq_theta(&c, tw + 1); int r = f(w, c); return cq_measure(r * r); }
int y3b(int w0, int c0, double tw) { int w = w0, c = c0, r = 0; cq_theta(&w, tw); cq_theta(&c, tw + 1); if (w & 1) r = f(w, c); return cq_measure(r * r); }
