struct N { int v; struct N *next; };
__attribute__((noinline)) static int f(struct N *n, int q) { return q * 3 + n->next->v; }
int ent_b4(int q0, double th, int a) {
  int q = q0; cq_theta(&q, th);
  struct N n2 = {7, 0};
  struct N n1 = {1, &n2};
  int r = f(&n1, q);
  n2.v = a;
  int s = (r & q) | 1;
  return cq_measure(s) + n2.v;
}
