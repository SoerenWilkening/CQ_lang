/* r7 (SQLite jsonExtractFunc, reduced): a classically bounded trip whose quantum branch has a classical branch in one arm
   (a real edge into the trip's join) while the other arm, walked later, enters the join with a literal under a quantum test
   it computes itself: on the region's real edge that arm's incoming is not on the path (its atoms are not lowered yet). */
int out[8], cnt;
__attribute__((noinline)) static int put(int v)
{
  out[cnt++ & 7] = v;
  return v;
}
int f(int *p, int n, unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int s = 0;
  for (int i = 1; i < n; i++) {
    int v;
    if ((x >> i) & 1) {
      if (p == 0)
        v = 1;
      else
        v = put(2 + *p);
    } else {
      unsigned t = x * (unsigned)(i + 3);
      if (t & 4)
        v = 4;
      else
        v = put(5);
    }
    s += v;
  }
  return s;
}
