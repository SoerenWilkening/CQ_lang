#include "CQ.h"
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int feenableexcept(int);
int fedisableexcept(int);
/* cq-a63l (CR rule 23 at f684858): the trap-enable extensions are rule 27 callees, not rule 23 state. */
int traps_then_flags(double c, double d) {
  feenableexcept(FE_DIVBYZERO);
  double x = cq_theta_f64(c, 1.0);
  double y = x / d;
  int r = fetestexcept(FE_DIVBYZERO) != 0;
  return r + (int)cq_measure_f64(y);
}
int trap_quantum_arg(int c) {
  int x = cq_theta_si32(c & 63, 1.0);
  feenableexcept(x);
  return cq_measure_si32(x);
}
