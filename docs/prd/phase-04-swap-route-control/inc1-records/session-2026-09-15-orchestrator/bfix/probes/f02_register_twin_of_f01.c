/* the ARRAY-FREE twin: the same stale read with no memory anywhere */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;                                /* the same SSA value */
  q = cq_theta(q, 0.7);                     /* NON-DIAGONAL, relabels the wire */
  return cq_measure(c) + cq_measure(q);
}
int main(void) { return slice(1); }
