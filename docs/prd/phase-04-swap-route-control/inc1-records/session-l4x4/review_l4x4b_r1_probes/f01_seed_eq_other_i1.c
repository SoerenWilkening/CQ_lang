/* f01 — F2 residual I-4: a SECOND live i1 `c` (derived forward from b) is
   pinned to the seed's value on the arm edge. Must still DECLINE. */
int slice(int y) {
  _Bool x = (y != 0);
  _Bool b = cq_theta(x, 0.5);
  _Bool c = !b;
  _Bool r = 0;
  if (!b) { r = cq_theta((_Bool)1, 0.9); }
  return (int)cq_measure(b) + (int)cq_measure(c) + (int)cq_measure(r);
}
int main(void){(void)slice(1);return 0;}
