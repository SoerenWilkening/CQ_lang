/* tests/calls probe (cq-4e6m; CR rules 18, 20, 23; 82 with 163 and 191): a clone carrying the floating-point
 * environment (FENV_ACCESS ON: strict ops, fenv_cells_lib.c) that writes the caller's cells: slot results beside
 * the flags (fe_cells), a cell it stores, reads back and stores again under a quantum predicate (fe_reread), and a
 * store through a pointer into a QRAM object (fe_qram: {stores..., flags}). The callers have no fenv state (mode 0,
 * an empty flags rail). Regenerate: clang -O1 fenv_cells.c; clang -O1 fenv_cells_lib.c; llvm-link -S both
 * -o fenv_cells.O1.ll */
#include "CQ.h"
void sc(double x, double *y);
int sc2(double x, double *y);
void addto(int *p, int *q, double z);
double fe_cells(double a) { double x = a; cq_theta(&x, 0.5); double y[2]; sc(x, y); return cq_measure(y[0] + y[1]); }
double fe_reread(double a) { double x = a; cq_theta(&x, 0.5); double y; int n = sc2(x, &y); return cq_measure(y + n); }
int fe_qram(unsigned x0, double tx, int a0, int a1) {
  unsigned x = x0; cq_theta(&x, tx); int a[2] = {a0, a1}; addto(a, a + (x & 1), (double)x - 3.0); return cq_measure(a[0]);
}
