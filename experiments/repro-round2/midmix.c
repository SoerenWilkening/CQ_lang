/* cq-iaz30 (GSL broyden_iterate): a case-3 loop whose bound is the classical conjunct of a mixed exit test
   (`r > 2 && i < 9 && t != 5`) in a block before the latch, which does the trip's work after it; an earlier quantum exit
   with an arm that keeps a store (one exit hub). */
int g[4];
int f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned t = 1, r;
  int i = 0;
  for (;;) {
    g[0] += 1;
    g[(i + 1) & 3] ^= (int)(t * 7);
    g[(i + 2) & 3] += (int)(t >> 1);
    g[(i + 3) & 3] -= (int)(t * t);
    if (((x >> (i & 15)) & 3) == 3) {
      g[1] = (int)t;
      return 9;
    }
    r = (x >> (i & 15)) & 7;
    if (!(r > 2 && i < 9 && t != 5))
      break;
    i++;
    t = t * 3 + r;
    g[3] += (int)t;
  }
  g[2] = (int)r;
  return (int)t;
}
