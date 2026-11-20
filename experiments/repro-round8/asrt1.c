/* r8: assertions (noreturn arms) inside a quantum-exit loop, with a memory effect after them in the same trip. */
void abort(void);
int g[8];
int asrt1(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 31;
  int s = 0;
  while (x != 0) {
    if (x == 6)
      abort();
    g[x & 7] += 1;
    if ((x & 7) == 5 && (x & 16))
      abort();
    s += (int)x;
    x >>= 1;
  }
  return s + g[1] + 2 * g[3];
}
