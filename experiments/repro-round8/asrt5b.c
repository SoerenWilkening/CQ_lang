/* r8: a header-tested quantum-exit loop (the region form) whose body asserts a classical condition and a quantum one. */
void abort(void);
int g[8];
int asrt5b(unsigned x0, double th, unsigned y)
{
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 31;
  int s = 0;
  unsigned k = 0;
  while (x != 0) {
    if (x == 6)
      abort();
    g[x & 7] += 1;
    if (k == (y & 3)) s += 100; if (0)
      abort();
    s += (int)x;
    x >>= 1;
    k++;
  }
  return s + g[1] + 2 * g[3];
}
