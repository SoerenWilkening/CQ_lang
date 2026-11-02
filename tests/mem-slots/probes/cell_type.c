/* tests/mem-slots probe (cq-366o; CR rules 20, 22): a local the program accesses only through a callee's formal
 * at another type than its declaration (musl frexp's int *e into a caller's long double buf[4]): its cells are the
 * accessed type. Regenerate: clang -O1 -include CQ.h cell_type.c -o cell_type.O1.ll */
__attribute__((noinline)) static double fr(double x, int *e) { if (x > 1.0) *e = 3; else *e = -2; return x * 0.5; }
double ct_buf(double a) { double x = a; cq_theta(&x, 0.5); long double buf[4] = {0}; return cq_measure(fr(x, (void *)buf)); }
double ct_buf2(double a) { double x = a + 1.0; cq_theta(&x, 0.25); long double buf[4] = {0}; return cq_measure(fr(x, (void *)buf)); }
