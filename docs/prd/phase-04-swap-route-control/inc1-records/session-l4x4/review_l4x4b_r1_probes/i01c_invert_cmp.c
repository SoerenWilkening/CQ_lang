/* i01c — i01's COMPARE twin, for the oracle. */
int slice(void) {
  int q = 3; int r = 7;
  q = cq_theta(q, 0.5);
  r = cq_theta(r, 0.25);
  cq_invert_begin();
  if (q == 5) { r = cq_theta(r, 0.9); }
  cq_invert_end();
  return cq_measure(q) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
