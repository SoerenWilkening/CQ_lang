/* a rotation of a computed rail in a by-name clone with a twin, no loop */
__attribute__((noinline)) static int fa(int v) {
  int x = v + 1;
  cq_theta(&x, 0.3);
  return x * 2;
}
int l2(int w0, double tw) {
  int w = w0;
  cq_theta(&w, tw);
  int r = fa(w);
  return cq_measure(r * r);
}
__attribute__((noinline)) static int fb(int c) {
  int x = c;
  cq_theta(&x, 0.3);
  int y = x + 1;
  return y * y;
}
int l3(int w0, double tw) {
  int w = w0;
  cq_theta(&w, tw);
  int r = fb(w);
  return cq_measure(r * r);
}
__attribute__((noinline)) static int fc(int c) { int x = c; cq_theta(&x, 0.3); int y = x + 1; cq_theta(&y, 0.2); return y * y; }
int l4(int w0, double tw) { int w = w0; cq_theta(&w, tw); int r = fc(w); return cq_measure(r * r); }
__attribute__((noinline)) static int fd(int v, int c) { int x = 0; if (c > 2) { x = c; cq_theta(&x, 0.3); } return x + v; }
int l5(int w0, double tw, int c) { int w = w0; cq_theta(&w, tw); int r = fd(w, c); return cq_measure(r * r); }
