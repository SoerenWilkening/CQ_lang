void e(int);
int f(int q, int b, int n, double *p) {
  if (q) return 0;
  if (b && *p < 0) return 1;
  for (int i = 0;; i++) {
    e(i);
    if (i >= n) break;
    e(-i);
    if (i >= 7) break;
  }
  *p = 1.0;
  return 0;
}
