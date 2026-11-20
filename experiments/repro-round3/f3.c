unsigned long VS, M1;
double D[8];
void report2(void);
void sw(unsigned long i, unsigned long k);
__attribute__((noinline)) static int f(int use) {
  if (use && VS != M1) {
    report2();
    return 20;
  }
  if (use && VS == 3) {
    report2();
    return 30;
  }
  for (unsigned long i = 0; i < VS - 1; i++) {
    unsigned long k = i;
    for (unsigned long j = i + 1; j < VS; j++) {
      if (D[2 * j] > 100.0)
        return 4;
      if (D[2 * j] < D[2 * k])
        k = j;
    }
    if (k != i)
      sw(i, k);
  }
  return 0;
}
int f3(unsigned long n, double a, int usem, double th) {
  unsigned long sz = n;
  cq_theta(&sz, th);
  M1 = 2;
  VS = 1 + (sz & 3);
  D[0] = a;
  D[2] = 1.0;
  D[4] = -a;
  return cq_measure(f(usem & 1));
}
