/* cq-aqr5v (block, cblas): inside a K-loop trip, a classically bounded loop with a quantum exit whose body joins after a
   classical exit test computed in an arm (k > 0, then c + k == 7); the bus store at the join runs under the K-loop guard's
   flag, which pred mints on each edge into the join, at the end of the earlier segments' blocks. */
int a[8];
int f(unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned n = x & 3;
  for (unsigned i = 0; i < n; i++) {
    for (int k = 0; k < 3; k++) {
      if (k > 0) {
        a[6] += 1;
        if (c + k == 7) { a[0] = 1; return 5; }
      }
      a[3 + k] += 1;
      if ((x >> (3 * i + k + 2)) & 1) { a[1] = 2; return 6; }
    }
  }
  return 0;
}
