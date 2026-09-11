/* i01 — cq_invert_begin/_end around a rail-controlled region. */
int slice(void) {
  _Bool b = 0; int r = 7;
  b = cq_theta(b, 0.5);
  r = cq_theta(r, 0.25);
  cq_invert_begin();
  if (b) { r = cq_theta(r, 0.9); }
  cq_invert_end();
  return (int)cq_measure(b) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
