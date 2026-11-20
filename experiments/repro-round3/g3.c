double Y[4], A[4];
__attribute__((noinline)) static int step(int q, long n) {
  int st = 0;
  for (int k = 0; k < 3; k++)
    if ((q >> k) & 1) {
      st = k + 1;
      goto out;
    }
  long i = 0;
  do
    Y[i & 3] = 0.5 * (Y[i & 3] + A[i & 3]);
  while (++i < n);
out:
  return st;
}
int g3(int q0, long n, double a, double th) {
  int q = q0;
  cq_theta(&q, th);
  A[1] = a;
  return cq_measure(step(q, n & 7));
}
