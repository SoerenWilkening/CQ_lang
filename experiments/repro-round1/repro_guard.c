/* cq-iaz30, reduced from GSL gsl_complex_arctan: a classical phi at the return join whose incoming
   block (the a != 0 arm) the walk runs under a guard, after a quantum branch region has closed. */
int f(int a, int b, int x0, double t) {
  if (b == 0)
    return a;
  int h = x0;
  cq_theta(&h, t);
  int i;
  if (h < 7)
    i = 100 / (h | 1);
  else
    i = 200 / (h | 3);
  if (a == 0) {
    if (b > 1)
      return 5;
    return b < -1 ? -5 : 0;
  }
  return 1000 / (h | 1) + i;
}
