/* y03 — a derived rail off q whose chain is DEAD (must be uncomputed by the
   whole-DAG spine) with a rail region rotating q in between. */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  _Bool b = cq_theta((_Bool)(q & 1), 0.5);
  int d = q & 6;
  if (b) { q = cq_theta(q, 0.9); }
  int e = d + q;
  return (int)cq_measure(b) + cq_measure(e);
}
int main(void){(void)slice(3);return 0;}
