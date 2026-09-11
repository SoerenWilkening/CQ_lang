/* n10 — NEGATED arm, rotated register read as data after the region. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (!b) { r = cq_theta(r, 0.9); }
  int s = r * 3;
  return (int)cq_measure(b) + cq_measure(s); }
int main(void){(void)slice();return 0;}
