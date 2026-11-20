/* cq-iaz30: a predicate whose atom is minted in a classical arm, read past n classical loops in a row. The
   facts past the loops (each a skip edge's guard or the exit's own atom) were a BDD of 2^n nodes: the pass
   ran for minutes (GSL ode-initval rk8pd_apply). */
int g[4];
__attribute__((noinline)) static int step(const int *p, unsigned dim, int q) {
  if (p && *p == q)
    return 1;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 1;
  if (g[0] == q) return 2;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 2;
  if (g[1] == q) return 3;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 3;
  if (g[2] == q) return 4;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 4;
  if (g[3] == q) return 5;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 5;
  if (g[0] == q) return 6;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 6;
  if (g[1] == q) return 7;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 7;
  if (g[2] == q) return 8;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 8;
  if (g[3] == q) return 9;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 9;
  if (g[0] == q) return 10;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 10;
  if (g[1] == q) return 11;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 11;
  if (g[2] == q) return 12;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 12;
  if (g[3] == q) return 13;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 13;
  if (g[0] == q) return 14;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 14;
  if (g[1] == q) return 15;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 15;
  if (g[2] == q) return 16;
  for (unsigned i = 0; i < dim; i++) g[i & 3] += 16;
  if (g[3] == q) return 17;
  return 0;
}
int loops_hang(unsigned dim, int q0, double th) {
  int q = q0, c = 3;
  cq_theta(&q, th);
  return cq_measure(step(dim & 1 ? &c : 0, dim & 7, q));
}
