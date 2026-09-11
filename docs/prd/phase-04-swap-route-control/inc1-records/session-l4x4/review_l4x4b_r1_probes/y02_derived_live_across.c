/* y02 — a DERIVED rail off q, live ACROSS a rail region whose arm rotates q:
   its uncompute (if any) would recompute on the ROTATED q. */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  _Bool b = cq_theta((_Bool)(q & 1), 0.5);
  int d = q & 6;
  if (b) { q = cq_theta(q, 0.9); }
  int e = d * 3;
  return (int)cq_measure(b) + cq_measure(q) + cq_measure(e);
}
int main(void){(void)slice(3);return 0;}
