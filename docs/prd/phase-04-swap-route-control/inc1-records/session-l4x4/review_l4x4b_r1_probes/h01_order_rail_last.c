/* h01 — H-1 part 2: the RAIL theta is LAST in source order; pass 1 lowers it
   FIRST. Does the emitted gate stream still follow source order? */
int slice(void) {
  int r = 7; int s = 9;
  r = cq_theta(r, 0.25);
  s = cq_theta(s, 0.35);
  _Bool b = 0; b = cq_theta(b, 0.5);
  if (b) { r = cq_theta(r, 0.9); }
  return (int)cq_measure(b) + cq_measure(r) + cq_measure(s);
}
int main(void){(void)slice();return 0;}
