/* Classical loops with data-dependent exits, nested loops and a quantum-looking name. */
double horner(const double *c, int n, double x) {
  double r = 0;
  for (int i = n - 1; i >= 0; i--) r = r * x + c[i];
  return r;
}

int collatz(unsigned n) {
  int steps = 0;
  while (n != 1) { n = (n & 1) ? 3 * n + 1 : n / 2; steps++; }
  return steps;
}

int cq_like_name(int a, int b) {
  int m = 0;
  for (int i = 0; i < a; i++)
    for (int j = 0; j < b; j++)
      if ((i ^ j) & 1) m += i * j; else m -= j;
  return m;
}
