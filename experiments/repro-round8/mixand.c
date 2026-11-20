/* r8 (GSL gsl_cdf_tdist_Pinv shape): a loop with quantum exits whose trip branches on `c > 5 && q` (rule 8: C && Q)
   into arms that meet at the latch. The edge of the C && Q arm into the join changed form under the isDate fix
   (real -> linearized): the result must stay the C program's. */
int f(int n, unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned y = x;
  for (int i = 0; i < n; i++) {
    if (y == 7)
      break;
    if (i == 5)
      break;
    unsigned z;
    if (c > 5 && (y & 1))
      z = y >> 1;
    else
      z = (c < 3 && (y & 2)) ? y >> 2 : y + 3;
    y = z;
    if ((y & 12) == 12)
      break;
  }
  return (int)y;
}
