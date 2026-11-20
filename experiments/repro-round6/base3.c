long out[8];
__attribute__((noinline)) static void put(int i, long k) { out[i & 7] = k; }
long f(int n, long y0, double th)
{
  long y = y0;
  cq_theta(&y, th);
  for (int i = 0; i < n; i++)
    if (y > 0) {
      y = y - 3;
      put(i, y);
    }
  return y;
}
