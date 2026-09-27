int h(int a, int k); int ext_f(int a);
__attribute__((noinline)) int f(int m) {
  int q = cq_theta(m, .5);
  int y = 0;
  if (q > 5) y = ext_f(7);
  int t = h(y, m);
  return t + cq_measure(y) + cq_measure(q);
}
int main(int c, char **v) { int r = f(c); if (r > 7) return 1; return r; }
