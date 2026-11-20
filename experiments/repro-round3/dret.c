double f(double q0, double th)
{
  double q = q0;
  cq_theta(&q, th);
  return q * 2.0;
}
