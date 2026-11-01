int gx;
__attribute__((noinline)) void g(int a) { gx = a; }
__attribute__((noinline)) static int f(int *p, int q) { return q * 3 + *p; }
int ent_b2(int q0, double th, int a) {
  int q = q0; cq_theta(&q, th);
  gx = 7;
  int r = f(&gx, q);
  g(a);
  int s = (r & q) | 1;
  return cq_measure(s) + gx;
}
