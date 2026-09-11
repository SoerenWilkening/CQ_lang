/* z01c — z01's COMPARE twin (int condition). */
__attribute__((noinline)) static int helper(int q, int r) {
  if (q == 5) { r = cq_theta(r, 0.9); }
  return r;
}
int slice(void) {
  int q = 3; int r = 7; int s = 9;
  q = cq_theta(q, 0.5); r = cq_theta(r, 0.25); s = cq_theta(s, 0.35);
  r = helper(q, r);
  s = helper(q, s);
  return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(void){(void)slice();return 0;}
