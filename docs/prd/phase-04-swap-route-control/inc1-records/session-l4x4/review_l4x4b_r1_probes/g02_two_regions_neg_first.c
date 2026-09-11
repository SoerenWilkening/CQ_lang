/* g02 — two regions on one b, the FIRST negated. */
int slice(void) { _Bool b=0; int r=7; int s=9;
  b=cq_theta(b,0.5); r=cq_theta(r,0.25); s=cq_theta(s,0.35);
  if (!b) { r = cq_theta(r, 0.9); }
  if (b)  { s = cq_theta(s, 0.7); }
  return (int)cq_measure(b) + cq_measure(r) + cq_measure(s); }
int main(void){(void)slice();return 0;}
