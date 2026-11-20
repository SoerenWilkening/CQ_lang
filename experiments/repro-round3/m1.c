__attribute__((noinline)) static int f(unsigned long n, int use, const double *d) {
  if (use && n != 2)
    return 20;
  for (unsigned long j = 1; j < n; j++)
    if (d[j] > 100.0)
      return 4;
  return 0;
}
double D[8];
int m1(unsigned long n, int use, double a, double th) {
  unsigned long sz = n;
  cq_theta(&sz, th);
  D[1] = a;
  return cq_measure(f(1 + (sz & 3), use & 1, D));
}
