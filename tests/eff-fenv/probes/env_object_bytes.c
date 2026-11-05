#include "CQ.h"
#include <fenv.h>
#include <string.h>
#pragma STDC FENV_ACCESS ON
/* cq-a63l (CR rule 23 at f684858): a fenv_t holding a quantum part whose bytes other code reads: the host part. */
int env_bytes(double c, double d) {
  fenv_t e;
  feclearexcept(FE_ALL_EXCEPT);
  double x = cq_theta_f64(c, 1.0);
  double y = x / d;
  fegetenv(&e);
  unsigned char b0;
  memcpy(&b0, &e, 1);
  feclearexcept(FE_ALL_EXCEPT);
  fesetenv(&e);
  return b0 + fetestexcept(FE_ALL_EXCEPT) + (int)cq_measure_f64(y);
}
