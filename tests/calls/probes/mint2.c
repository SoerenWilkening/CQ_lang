__attribute__((noinline)) static int f(int a, int c, double t) {
  int y = c;
  cq_theta(&y, t);
  return y * a;
}
int mint2(int x0, double tx, double t, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int r = f(x, c, t);
  return cq_measure(r * r);
}
