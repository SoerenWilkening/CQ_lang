__attribute__((noinline)) static int f(int *p, int *s, int a, int q) { int t = *s; *p = a; return q * 3 + t; }
int ent_a2(int q0, double th, int a) {
  int q = q0; cq_theta(&q, th);
  int x = 7;
  int r = f(&x, &x, a, q);
  int s = (r & q) | 1;
  return cq_measure(s) + x;
}
