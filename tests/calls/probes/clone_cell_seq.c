/* tests/calls probe (cq-4e6m; CR rules 9, 18, 20): a clone that writes a caller cell, reads it back and writes it
 * again, in sequence and under quantum predicates (musl __rem_pio2 / __rem_pio2f writing *y): the cell is one value
 * of the clone (select per predicated store), one slot result at the return. -frounding-math keeps the stores.
 * Regenerate: clang -O1 -frounding-math clone_cell_seq.c -o clone_cell_seq.O1.ll */
#include "CQ.h"
__attribute__((noinline)) void two(double x, double *y) { *y = x * 2.0; *y = *y + 1.0; }
double u_two(double a) { double x = a; cq_theta(&x, 0.5); double y; two(x, &y); return cq_measure(y); }
__attribute__((noinline)) int cond(double x, double *y) { int n = 0; *y = x * 2.0; if (*y > 1.0) { n = 1; *y = x - 1.0; } return n; }
double u_cond(double a) { double x = a; cq_theta(&x, 0.5); double y; int n = cond(x, &y); return cq_measure(y + n); }
__attribute__((noinline)) void pair(double x, double *y) { if (x > 0.5) { y[0] = x * 3.0; y[1] = (x - y[0]) * 0.5; } else { y[0] = x; y[1] = 0.25; } }
double u_pair(double a) { double x = a; cq_theta(&x, 0.5); double y[2]; pair(x, y); return cq_measure(y[0] + y[1]); }
