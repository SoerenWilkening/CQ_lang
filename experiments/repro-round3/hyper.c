/* cq-iaz30 (GSL gsl_ran_hypergeometric, reduced): two K-loops on the two sides of a quantum branch, both exiting into the
   return. The second loop's normal exit runs `t - k` (its exit arm), a block also entered from outside it (its tail, when
   n <= t). The first loop, lowered first, left that block's edge into the return to the walker under the edge's whole
   predicate, which on the second loop's paths reads one trip's atoms after its last trip. */
static unsigned hyp(unsigned seed, unsigned n1, unsigned n2, unsigned t)
{
  const unsigned n = n1 + n2;
  unsigned i, a = n1, b = n1 + n2, k = 0;
  if (t > n)
    t = n;
  if (t < n / 2) {
    for (i = 0; i < t; i++) {
      unsigned u = (seed >> (i & 15)) & 7;
      if (b * u < 8 * a) {
        k++;
        if (k == n1)
          return k;
        a--;
      }
      b--;
    }
    return k;
  } else {
    for (i = 0; i < n - t; i++) {
      unsigned u = (seed >> (i & 15)) & 7;
      if (b * u < 8 * a) {
        k++;
        if (k == n1)
          return t - k;
        a--;
      }
      b--;
    }
    return t - k;
  }
}
unsigned f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  return hyp(x >> 10, x & 7, (x >> 3) & 7, (x >> 6) & 15);
}
