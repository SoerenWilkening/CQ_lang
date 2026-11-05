__attribute__((noinline)) static int m(int v, int c) {
  int r = 0;
  if (v > 1)
    r = cq_measure(v);
  return r + c;
}
int ctl_measure_arm(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int r = 7;
  if (x & 1)
    r = m(x, c);
  return cq_measure(r);
}
