/* y01 — the arm rotates q, which is an ANCESTOR of the rail b's wire (R4's
   subject for the compare form). */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  _Bool b = cq_theta((_Bool)(q & 1), 0.5);
  if (b) { q = cq_theta(q, 0.9); }
  return (int)cq_measure(b) + cq_measure(q);
}
int main(void){(void)slice(3);return 0;}
