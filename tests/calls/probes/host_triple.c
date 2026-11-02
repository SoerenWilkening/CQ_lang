/* tests/calls probe (cq-sd95; CR rule 21, §1.4; musl erfl's __polevll over its P and Q tables): a readonly
 * pointer formal reached at two call sites with host tables of different lengths crosses as a triple with a
 * classical tag and idx; the clone reads the coefficients through the caller's classical pointer.
 * Regenerate: clang -O1 host_triple.c; clang -O1 host_triple_lib.c; llvm-link -S both -> host_triple.O1.ll. */
long double pol(long double x, const long double *P, int n);
static const long double A[3] = {1.0L, 2.0L, 3.0L};
static const long double B[4] = {4.0L, 5.0L, 6.0L, 7.0L};
long double f_tables(long double x) {
  cq_theta(&x, 0.3);
  long double r = pol(x, A, 2) / pol(x, B + 1, 2);
  return cq_measure(r);
}
