/* GMP mpn_mul_fft_decompose (reduced, cq-vs1eo): a classically bounded loop whose trip holds a quantum branch; the arm
   the walk takes first holds a classical branch (`c != -1`) whose arms both go straight to the trip's join (the latch),
   while the other quantum arm still has code to walk. */
long out[8], out2[8];
__attribute__((noinline)) static void put(int i, long k) { out[i & 7] = k; }
__attribute__((noinline)) static void clr(int i, long c) { out2[i & 7] = c; }
long f(int n, long c, long y0, double th)
{
  long y = y0;
  cq_theta(&y, th);
  for (int i = 0; i < n; i++) {
    if (y <= 0) {
      if (c != -1)
        clr(i, c);
    } else {
      long k = y >= 3 && i < 2 ? 3 : y;
      y = y - k;
      put(i, k);
    }
  }
  return y;
}
