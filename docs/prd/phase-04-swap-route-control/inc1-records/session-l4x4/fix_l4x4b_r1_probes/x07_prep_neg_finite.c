/* x07 — x06's FINITE control: must keep accepting. */
int slice(void) { _Bool b=0; int r=5; b=cq_theta(b,0.5);
  if (!b) { r = cq_theta(5, 0.9); }
  return (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
