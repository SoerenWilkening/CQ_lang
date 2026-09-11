/* x03 — NEGATED rail arm, angle -inf. Non-finite: must DECLINE like +inf/NaN. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (!b) { r = cq_theta(r, -__builtin_inf()); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
