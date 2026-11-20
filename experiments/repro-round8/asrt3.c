/* r8: an assertion with a classical condition in a quantum-exit loop (stays a real branch), and a quantum one. */
void abort(void);
int g[8];
int asrt3(unsigned x0, double th, unsigned y)
{
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 31;
  int s = 0;
  unsigned k = 0;
  while (x != 0) {
    if (k == (y & 7))
      abort();
    g[k & 7] = (int)x;
    if (x == 9)
      abort();
    s += g[(x + k) & 7];
    x >>= 1;
    k++;
  }
  return s;
}
