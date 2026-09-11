/* h03 — H-1(c): the CONTROL theta's own angle is QUANTUM-DERIVED, so its
   rotation lowering declines. What is left in the module? */
int slice(void) {
  double a = 0.5; int r = 7;
  a = cq_theta(a, 0.25);
  _Bool b = cq_theta((_Bool)0, a);
  r = cq_theta(r, 0.25);
  if (b) { r = cq_theta(r, 0.9); }
  return (int)cq_measure(b) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
