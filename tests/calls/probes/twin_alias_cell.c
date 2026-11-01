__attribute__((noinline)) static int f(int *p, int *s, int q) { int t = *s; *p = q + 1; return q * 3 + t; }
int ent_c1(int q0, double th, int a) {
  int q = q0; cq_theta(&q, th);
  int x = a;
  int r = f(&x, &x, q);
  int z = (r & q) | 1;
  return cq_measure(z);
}
