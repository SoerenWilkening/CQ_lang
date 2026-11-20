/* cq-11qhg (GSL fd_asymp): in a classically bounded loop with a mixed latch exit (`k <= 12 && !stop`), a quantum test
   inside one classical arm of the trip (c false) leaves for the latch and otherwise falls into the classical join of
   that arm, where another quantum test follows. */
int a[16];
int f(unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned sum = 1, last = 1000;
  int stop = 0;
  for (int k = 1; k <= 12 && !stop; k++) {
    unsigned t = ((x >> (k & 15)) & 7) + (unsigned)k;
    if (!c) {
      a[15] += 1;
      if (t > last) {
        stop = 1;
        continue;
      }
    }
    a[k] += (int)t;
    a[k - 1] ^= (int)sum;
    if (t * 3 < sum) {
      stop = 1;
      continue;
    }
    sum += t;
    last = t;
  }
  return (int)sum;
}
