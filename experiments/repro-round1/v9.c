int f(long *x, int *io) {
  long n = *x;
  if (io != 0 && *io != n) return 19;
  for (long i = 0; i < n; ++i)
    if (io) io[i] = 1;
  return 0;
}
