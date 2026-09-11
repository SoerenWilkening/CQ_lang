/* v01 — b is the TARGET of region 1's controlled Ry and the CONTROL of region 2. */
int slice(void) { _Bool c=0; _Bool b=0; int r=7;
  c = cq_theta(c, 0.3); b = cq_theta(b, 0.5); r = cq_theta(r, 0.25);
  if (c) { b = cq_theta(b, 0.2); }
  if (b) { r = cq_theta(r, 0.9); }
  return (int)cq_measure(c) + (int)cq_measure(b) + cq_measure(r); }
int main(void){(void)slice();return 0;}
