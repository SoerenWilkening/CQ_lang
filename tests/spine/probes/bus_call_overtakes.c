/* tests/spine probe (CR rule 5): a call of a function that writes memory overtakes a load copy read after it; a call of
 * one that does not leaves it. */
int cell = 2, other = 3, sink;
__attribute__((noinline)) static void writes(int v) { other = v; }
int call_overtakes(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int t = cell + x;
  writes(c);
  int u = t * 3;

  return cq_measure(u);
}
