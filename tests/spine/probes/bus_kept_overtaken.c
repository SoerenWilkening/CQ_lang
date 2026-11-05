/* tests/spine probe (CR rule 5 sentences 1, 3): 202's shape on a global: a copy un-copied and freed before the store, a
 * copy the store overtakes (un-copied, not freed), a kept store at an address rail, a measured copy. */
int a[4] = {1, 2, 3, 4};
int kept_overtaken(unsigned k0, double tk, int y0, double ty, double p1, double p2) {
  unsigned k = k0;
  cq_theta(&k, tk);
  int y = y0;
  cq_theta(&y, ty);
  if (a[k & 3] > 2)
    cq_phi(p1);
  int t = a[(k >> 2) & 3];
  a[k & 3] = y;
  if (t > 2)
    cq_phi(p2);
  return cq_measure(a[0]);
}
