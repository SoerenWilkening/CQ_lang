#include "CQ.h"
/* cq-1c5j (CR rules 18, 20, 21): one clone handed a slot object by two callers (musl's __rem_pio2(x, y) from sin and cos). */
__attribute__((noinline)) static int split2(double x, double *y) { y[0] = x * 0.5; y[1] = x - y[0]; return x > 1.0; }
__attribute__((noinline)) static double fa(double x) { double y[2]; int n = split2(x, y); return n ? y[0] : y[1]; }
__attribute__((noinline)) static double fb(double x) { double y[2]; int n = split2(x, y); return n ? y[1] + 1.0 : y[0]; }
double clone_triple_two_callers(double x0) { double x = x0; cq_theta(&x, 0.3); return cq_measure(fa(x) + fb(x)); }
