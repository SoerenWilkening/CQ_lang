/* The bd `3d8q` STALE-READER shape, laundered through a rail BANK.
   The cells park q's rail NAME; q is then rotated NON-DIAGONALLY; the cells
   are measured afterwards.  The source says the cells hold q-before-the-second
   rotation; the emitted circuit measures q-after. */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  q = cq_theta(q, 0.7);                     /* NON-DIAGONAL, relabels the wire */
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
