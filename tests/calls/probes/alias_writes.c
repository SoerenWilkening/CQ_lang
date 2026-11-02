/* tests/calls probe (cq-366o; CR rule 18 twin point, cq-aqk1): one pointer handed to two pointer formals the clone
 * writes through (musl sincos(x, buf, buf)): the call is a call of the callee's alias variant, one route per cell.
 * Regenerate: clang -O1 -include CQ.h alias_writes.c -o alias_writes.O1.ll */
__attribute__((noinline)) static void sc(double x, double *s, double *c) {
  if (x > 0.5) { *s = x * 3.0; *c = x - 1.0; } else { *c = x + 2.0; *s = x * 0.25; }
}
double aw_same(double a) { double x = a; cq_theta(&x, 0.5); double y = 0.0; sc(x, &y, &y); return cq_measure(y); }
__attribute__((noinline)) static void sc2(double x, double *s, double *c) { *s = x * 3.0; *c = *s + x; }
double aw_rmw(double a) { double x = a; cq_theta(&x, 0.5); double y = 1.0; sc2(x, &y, &y); return cq_measure(y); }
__attribute__((noinline)) static int sc3(double x, double *s, double *c) { *c = x; return 1; }
int aw_buf(double a) { double x = a; cq_theta(&x, 0.5); long double buf[4] = {0}; return sc3(x, (void *)buf, (void *)buf); }
