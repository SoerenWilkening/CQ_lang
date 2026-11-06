/* tests/calls probe (CR rule 18): rd's twin runs after the merge. The store in the other arm is emitted between the call and
 * the twin but lies on no path from the call: no change comes first, the result is zeroed and freed, never kept. */
static const int T[4] = {5, 7, 11, 13};
int cell;
__attribute__((noinline)) int rd(int x) { return T[x & 3] + x; }
int other_arm(int x0, double t) {
  int x = x0;
  cq_theta(&x, t);
  int r;
  if (x > 3) {
    r = rd(x) * 3;
  } else {
    cell = x;
    r = x + 1;
  }
  return cq_measure(r);
}
