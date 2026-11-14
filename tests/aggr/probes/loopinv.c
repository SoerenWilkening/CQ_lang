// cq-941o: a vector lane computed before a loop and read by every trip; lane rule 6 must not clean it in the body.
typedef long v2 __attribute__((vector_size(16)));
long l_invariant(int n) {
  long x = 0, y = 0;
  cq_theta(&x, 1.0); cq_theta(&y, 1.0);
  v2 v = (v2){x, y} * 3;
  long s = 0;
  for (int i = 0; i < n; i++) {
    v2 w = v + (v2){i, 2 * i};
    s += cq_measure(w[0] ^ w[1]);
  }
  return s;
}
