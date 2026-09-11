/* z01 — the rail-controlled region lives in a NOINLINE callee that Phase-6
   clone-on-taint specializes; called TWICE. */
__attribute__((noinline)) static int helper(_Bool b, int r) {
  if (b) { r = cq_theta(r, 0.9); }
  return r;
}
int slice(void) {
  _Bool b = 0; int r = 7; int s = 9;
  b = cq_theta(b, 0.5); r = cq_theta(r, 0.25); s = cq_theta(s, 0.35);
  r = helper(b, r);
  s = helper(b, s);
  return (int)cq_measure(b) + cq_measure(r) + cq_measure(s);
}
int main(void){(void)slice();return 0;}
