/* g04 — NEGATED controlled state prep, int seed, register measured. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5);
  if (!b) { r = cq_theta(7, 0.9); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
