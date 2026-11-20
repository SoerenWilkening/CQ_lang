/* cq-03rdt (GSL linalg complex_tri_invert_L3): a K-loop (quantum trip count) whose trip, under a classical
   condition, calls a declared clone (rule 27: cinv is listed in --cq-roots with no body here) returning two
   doubles, stores both and reads one again. Each result is first copied for its store; the call's own results
   stay garbage, which the twin zeroes in the loop's reverse. Before the fix the second result was kept as if a
   merge, which kept the first, and uncompute found no point for the first's instances (cyclePoint).
   Build: cqcc -S --cq-roots cplx_decl.roots --cq-check --cq-entry cplx_decl cplx_decl.c */
typedef struct { double dat[2]; } cx;
double acc[2];
cx cinv(double a, double b);
__attribute__((noinline)) void scal(double r) { acc[0] += r; }
__attribute__((noinline)) void body(double *m, long n, int up) {
  for (long k = 0; k < n; ++k) {
    double r = -1.0;
    if (up) {
      cx z = cinv(m[2 * k], m[2 * k + 1]);
      m[2 * k] = z.dat[0];
      m[2 * k + 1] = z.dat[1];
      r = -z.dat[0];
    }
    scal(r);
  }
}
double cplx_decl(long n0, int up, double a, double b, double th) {
  double m[8] = {a, b, b, a, a, b, b, a};
  long n = n0 & 3;
  cq_theta(&n, th);
  body(m, n, up);
  return cq_measure(m[0] + m[1] + m[2] + acc[0]);
}
