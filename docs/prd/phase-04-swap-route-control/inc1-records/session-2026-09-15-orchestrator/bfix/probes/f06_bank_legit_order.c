/* the LEGITIMATE sibling of f01: the bank is measured BEFORE q is re-rotated.
   One line apart from f01 and it denotes a DIFFERENT circuit. */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
