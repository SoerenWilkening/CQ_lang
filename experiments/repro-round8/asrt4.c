/* r8: an assertion in a nested quantum-exit loop and one in the outer trip after it. */
void abort(void);
int g[8];
int asrt4(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 15;
  int s = 0;
  while (x != 0) {
    unsigned z = x;
    while (z & 1) {
      if (z == 7)
        abort();
      s++;
      z >>= 1;
    }
    if (z == 2 && s > 2)
      abort();
    g[s & 7] += (int)z;
    x >>= 1;
  }
  return s + g[2];
}
