/* cq-88vg (52's shape): a measured classical switch phi whose arms are caller cells a clone wrote (the twin's
 * slot outs, loaded right after the call): each such arm is copied into a fresh rail on its own edge; the
 * twin of a clone with a classical result and cell copy-outs drops the result. */
__attribute__((noinline)) static int put2(int x, int n, int *out) { out[0] = x + 1; out[1] = x ^ 5; return n + 1; }
int sw(int x0, double th, int n) {
  int x = x0;
  cq_theta(&x, th);
  int y[2];
  int m = put2(x, n, y);
  int r;
  switch (m & 3) {
  case 0: r = y[0]; break;
  case 1: r = y[1]; break;
  default: r = y[0] - y[1]; break;
  }
  return cq_measure(r) + cq_measure(x);
}
