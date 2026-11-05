__attribute__((noinline)) static int a1(int v) { return v + 1; }
__attribute__((noinline)) static int a2(int v) { return v * 3; }
int fp_under_pred(int x0, double tx, int w, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int (*fp)(int) = w ? a1 : a2;
  int r = c;
  if (x > 2)
    r = fp(x);
  return cq_measure(r);
}
