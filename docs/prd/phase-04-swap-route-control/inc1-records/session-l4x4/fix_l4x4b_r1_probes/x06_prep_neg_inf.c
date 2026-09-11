/* x06 — NEGATED STATE PREP with +inf: the prep also duplicates the angle
   (alloc(SEED); ry(h,θ); cry(h_b,h,−θ)), so the same fence must cover it. */
int slice(void) { _Bool b=0; int r=5; b=cq_theta(b,0.5);
  if (!b) { r = cq_theta(5, __builtin_inf()); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
