/* h02 — H-1 part 2 with a CHAINED rail (b0 -> b) declared last, plus a
   derived data chain on another register that the spine must uncompute. */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  int a = q * 5;
  int c = a + 3;
  _Bool b0 = 0; b0 = cq_theta(b0, 0.3);
  _Bool b = cq_theta(b0, 0.2);
  int r = 7; r = cq_theta(r, 0.25);
  if (b) { r = cq_theta(r, 0.9); }
  return cq_measure(c) + cq_measure(r) + (int)cq_measure(b);
}
int main(void){(void)slice(3);return 0;}
