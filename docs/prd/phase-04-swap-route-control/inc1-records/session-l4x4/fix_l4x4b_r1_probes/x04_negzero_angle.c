/* x04 — NEGATED rail arm, angle -0.0. FINITE: must keep ACCEPTING. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (!b) { r = cq_theta(r, -0.0); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
