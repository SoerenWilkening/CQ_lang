/* s02 — b is NOT measured but a chain borrowing b IS measured (the borrow's
   uncompute crosses the controlled gate). */
int slice(void) {
  _Bool b=0; int r=7;
  b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (b) { r = cq_theta(r, 0.9); }
  int s = r + (int) b;
  return cq_measure(s);
}
int main(void){(void)slice();return 0;}
