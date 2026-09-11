/* u01 — b borrowed as DATA BEFORE the region; the uncompute of that borrow
   lands AFTER the controlled gate. */
int slice(void) { _Bool b=0; int r=7; b=cq_theta(b,0.5);
  int z = (int) b + 4;
  r=cq_theta(r,0.25);
  if (b) { r = cq_theta(r, 0.9); }
  return cq_measure(z) + cq_measure(r); }
int main(void){(void)slice();return 0;}
