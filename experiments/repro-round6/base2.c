long out2[8];
long f(int n, long c, long y0, double th)
{
  long y = y0;
  cq_theta(&y, th);
  for (int i = 0; i < n; i++)
    if (y <= 0)
      out2[i & 7] = c;
    else
      y = y - 3;
  return y;
}
