__attribute__((noinline)) static int inc(int v) { return v + 1; }
__attribute__((noinline)) static int dec(int v) { return v - 1; }
static int (*const tab[2])(int) = {inc, dec};
int q3(int x0, double tx, int c) {
  int x = x0, y = x0 + 2;
  cq_theta(&x, tx);
  cq_theta(&y, tx + 1);
  int r = tab[y & 1](x);
  int s = r * c + 1;
  return cq_measure(s ^ y);
}
