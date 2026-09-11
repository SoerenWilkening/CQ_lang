/* x01 — NEGATED rail arm with a NON-FINITE CONSTANT angle (+inf). The source's
   b=1 branch is the IDENTITY; the emitted pair is Ry(inf)Ry(-inf). */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (!b) { r = cq_theta(r, __builtin_inf()); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
