__attribute__((noinline)) int wrap(int a, int (*cmp)(int)) { return cmp(a); }
static int inc(int v) { return v + 1; }
int (*volatile vp)(int) = inc;
int q1(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  return cq_measure(wrap(x, vp) + c);
}
