/* rule 18 (rulings3 F): a rotation in a loop leaves no twin, the result is KEPT; through a rail the table clone pushes per mint */
__attribute__((noinline)) static int f(int v) {
  int a = 0;
  for (int i = 0; i < 3; i++) {
    int x = v + i;
    cq_theta(&x, 0.3);
    a += x;
  }
  return a;
}
int r1(int v) { return f(v); }
/* a caller whose result needs f's joins the list */
__attribute__((noinline)) static int g(int v) { return f(v) + 1; }
int r2(int v) { return g(v) * 2; }
__attribute__((noinline)) static int h(int v) { int a = 0; for (int i = 0; i < 3; i++) { int x = v + i; cq_theta(&x, 0.3); a += x; } return a; }
__attribute__((noinline)) static int k(int v) { return v - 1; }
static int (*const tab[2])(int) = {h, k};
int r3(int v) { return tab[v & 1](v); }
