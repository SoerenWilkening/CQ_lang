/* g01 — NEGATED controlled state prep whose fresh rail is DEAD. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5);
  if (!b) { r = cq_theta(7, 0.9); }
  (void) r;
  return (int)cq_measure(b); }
int main(void){(void)slice();return 0;}
