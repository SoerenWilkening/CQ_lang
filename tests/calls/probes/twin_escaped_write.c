int *gp;
__attribute__((noinline)) void g(int a) { *gp = a; }
__attribute__((noinline)) static int f(int *p, int q) { return q * 3 + *p; }
int ent_b1(int q0, double th, int a) {
  int q = q0; cq_theta(&q, th);
  int x = 7;
  gp = &x;
  int r = f(&x, q);
  g(a);
  int s = (r & q) | 1;
  return cq_measure(s) + x;
}
