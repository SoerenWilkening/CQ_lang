/* tests/chk-kept, CR rule 18: a lost twin the leak rule must reject; see the mutant in test_kept.py. */
static const int T[4] = {5, 7, 11, 13};
int cell;
__attribute__((noinline)) int rd(int x) { return T[x & 3] + x; }
int p4(int x0, double t) { int x = x0; cq_theta(&x, t); int y = rd(x) & 6; return cq_measure(y); }
