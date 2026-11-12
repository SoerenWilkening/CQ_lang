/* tests/spine probe (CR rule 2, "Collapse is static"; cq-8nj3o, cq-yjbwv): taint and the spine decide by one static
 * predicate (cq::measuredBefore) whether a read sees a measured value. A measurement in a quantum arm runs
 * unconditionally (p1, p9: the later branch is classical); one on a classical path only leaves the value a rail (p8);
 * one in a loop arm leaves the read of the next trip a rail (loopm). Each once stopped the pass with
 * "spine: rail() of a classical value".
 * Regenerate collapse_static.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h collapse_static.c */

int p1(int k) {
  int x = 0, y = 0, z = 0;
  cq_theta(&x, 0.5); cq_theta(&y, 0.25); cq_theta(&z, 0.75);
  int m = 0;
  if (x > k) m = cq_measure(y);          /* quantum arm: unconditional */
  int mx = cq_measure(x);                 /* now m, mx classical */
  int r = 0;
  if (m + mx > 3) r = cq_measure(z);      /* classical branch on measured outcomes */
  return r + m + mx;
}

int p8(int c) {
  int x = 0, y = 0; cq_theta(&x, 0.5); cq_theta(&y, 0.25);
  int t = 0, r = 0;
  if (c) t = cq_measure(x);
  if (x > 3) r = cq_measure(y);
  return r + t;
}

int p9(int k) {
  int x = 0, y = 0, z = 0;
  cq_theta(&x, 0.5); cq_theta(&y, 0.25); cq_theta(&z, 0.75);
  int t = 0, r = 0;
  if (y > k) t = cq_measure(x);
  if (x > 3) r = cq_measure(z);
  return r + t + cq_measure(y);
}
int loopm(unsigned n, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  int s = 0;
  for (unsigned i = 0; i < n; i++) {
    if ((x >> i) & 1) cq_measure(x);
  }
  return s;
}
