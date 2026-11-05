__attribute__((noinline)) static int h1(int a) { int y = 3; cq_theta(&y, .5); return y * a; }
__attribute__((noinline)) static int h2(int a) { return a + 2; }
int (*const volatile dummy)(int) = 0;
int tbl_mint(int x0, double tx, int w) {
  int x = x0;
  cq_theta(&x, tx);
  int (*fp)(int) = w ? h1 : h2;
  int r = fp(x);
  return cq_measure(r * r);
}
