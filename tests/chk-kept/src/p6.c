/* tests/chk-kept, CR rule 18: a lost twin the leak rule must reject; see the mutant in test_kept.py. */
static const int T[4] = {5, 7, 11, 13};
int cell;
__attribute__((noinline)) int rd(int x) { return T[x & 3] + x; }
int p6(int n, int x0, double t) { int x = x0; cq_theta(&x, t);
  for (int i = 0; i < (n & 1) + 3; i++) {
    int r = rd(x + i);
    if (r > 7) cq_phi(t);
    cell = i;
  }
  int z = rd(x) & 5;
  return cq_measure(z); }
