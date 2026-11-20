/* cq-11qhg: as qarm.c with exit arms that keep nothing (no hub): the exit value is computed in the classical arm. */
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned s = 1;
  for (int k = 0; k < n && k < 6; k++) {
    if (k & 1) {
      unsigned t = s * 3 + x;
      if ((t >> k) & 1) return (int)(t + 7);
    }
    s += x >> k;
    if ((s & 7) == 5) return 100 + k;
  }
  return (int)s;
}
