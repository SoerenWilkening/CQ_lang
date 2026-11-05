__attribute__((noinline)) static int a1(int v) { return v + 1; }
__attribute__((noinline)) static int a2(int v) { return v * 3; }
static int (*const tab[2])(int) = {a1, a2};
int fp_rail_unmeasured(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  int r = tab[x & 1](c);
  return cq_measure(r * r);
}
