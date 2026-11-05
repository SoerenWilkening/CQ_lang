__attribute__((noinline)) static int a1(int v) { return v + 1; }
__attribute__((noinline)) static int a2(int v) { return v * 3; }
int fp_classical(int x0, double tx, int w, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int (*fp)(int) = w ? a1 : a2;
  int r = fp(c);
  return cq_measure(x) + cq_measure(r);
}
