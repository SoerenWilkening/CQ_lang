typedef struct { unsigned long size1, size2; } mat;
mat Mx = {2, 2};
unsigned long VS;
double D[8];
__attribute__((noinline)) static int f(mat *evec) {
  if (evec && evec->size1 != evec->size2)
    return 20;
  else if (evec && VS != evec->size1)
    return 20;
  const unsigned long N = VS;
  for (unsigned long i = 0; i < N - 1; i++)
    for (unsigned long j = i + 1; j < N; j++)
      if (D[2 * j] > 100.0)
        return 4;
  return 0;
}
int m3(unsigned long n, double a, int usem, double th) {
  unsigned long sz = n;
  cq_theta(&sz, th);
  VS = 1 + (sz & 3);
  D[0] = a;
  D[2] = 1.0;
  D[4] = -a;
  return cq_measure(f(usem & 1 ? &Mx : 0));
}
