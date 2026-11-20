__attribute__((noinline)) static int f(unsigned long n, int use) {
  if (use && n != 2)
    return 20;
  for (unsigned long j = 1; j < n; j++)
    if (j == 7)
      return 4;
  return 0;
}
int m2(unsigned long n, int use, double th) {
  unsigned long sz = n;
  cq_theta(&sz, th);
  return cq_measure(f(1 + (sz & 3), use & 1));
}
