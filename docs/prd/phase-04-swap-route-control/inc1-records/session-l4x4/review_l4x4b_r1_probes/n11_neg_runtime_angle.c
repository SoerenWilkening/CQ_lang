/* n11 — NEGATED arm with a CLASSICAL RUN-TIME angle (the CreateFNeg path). */
int slice(double a) { _Bool b=0; int r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (!b) { r = cq_theta(r, a); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice(0.4);return 0;}
