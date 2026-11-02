/* tests/calls probe (cq-4e6m; CR rules 19, 23; 82 in rule 19's arms): an indirect call whose candidates carry the
 * floating-point environment (FENV_ACCESS ON, fenv_indirect_lib.c) or not: each arm's flags (the clone's new
 * ones, else a copy of the caller's) merge at the join. Under a quantum predicate too (fi_pred).
 * Regenerate: clang -O1 fenv_indirect.c; clang -O1 fenv_indirect_lib.c; llvm-link -S both -o fenv_indirect.O1.ll */
#include "CQ.h"
double fhalf(double x);
double fplain(double x);
__attribute__((noinline)) double (*pick(int c))(double) { return c ? fhalf : fplain; }
double fi_call(double a, double t, int c) { double x = a; cq_theta(&x, t); return cq_measure(pick(c)(x)); }
double fi_pred(double a, double t, int c) {
  double x = a; cq_theta(&x, t);
  double r = 1.0;
  if (x > 0.5) r = pick(c)(x);
  return cq_measure(r);
}
