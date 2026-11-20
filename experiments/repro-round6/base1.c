long f(int n, long y0, double th)
{
  long y = y0;
  cq_theta(&y, th);
  for (int i = 0; i < n; i++)
    if (y > 0)
      y = y - 3;
  return y;
}
