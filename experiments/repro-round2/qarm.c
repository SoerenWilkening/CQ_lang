/* cq-11qhg: a classically bounded loop (case 3) whose quantum exit test sits in a classical arm of the trip (k & 1) that
   rejoins before the latch; the exit arm keeps a store, so the exits meet at one hub. */
int a[8];
int f(unsigned x0, double th, int n)
{
  unsigned x = x0;
  cq_theta(&x, th);
  for (int k = 0; k < n && k < 6; k++) {
    if (k & 1) {
      a[6] += 1;
      if ((x >> k) & 1) { a[0] = k; return 5; }
    }
    a[1 + k] += 1;
    if (((x >> (k + 1)) & 3) == 3) { a[7] = 2; return 6; }
  }
  return 0;
}
