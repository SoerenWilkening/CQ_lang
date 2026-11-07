/* tests/chk-kept (rule 19, §1.4): q1 with a classical function pointer. The call is the table clone's `_t` and its twin `_t_unc`,
 * which zeroes and frees the result. q1's pointer is a volatile load, a rail (rules 20, 24), so it reaches `_t_ctl` instead. */
__attribute__((noinline)) int wrap(int a, int (*cmp)(int)) { return cmp(a); }
static int inc(int v) { return v + 1; }
static int dec(int v) { return v - 1; }
int q1c(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  return cq_measure(wrap(x, c ? dec : inc));
}
