/* cq-rb96s (GMP block_resieve, reduced): a K-loop whose only way out lies behind a quantum branch, the exit test itself
   classical. The arm post-dominates the header, so taint saw no tainted control dependence for it or the store in it,
   while the trip runs it under the quantum predicate (rule 14). */
unsigned tab[4];
unsigned out[4];
int resieve(unsigned x0, double th, unsigned n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  tab[0] = x & 1;
  tab[1] = (x >> 1) & 1;
  tab[2] = 1;
  tab[3] = x >> 2;
  unsigned i = 0;
  for (;;) {
    i++;
    if (tab[i & 3] & 1) {
      if (i > (n & 3))
        break;
      out[i & 3] |= i;
    }
  }
  return out[1] + out[2] + out[3] * 16;
}
