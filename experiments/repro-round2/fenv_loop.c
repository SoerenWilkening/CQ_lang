/* cq-03rdt (GSL ode-initval2 rk2imp_apply): a classically bounded loop raises quantum flags in
   every trip; the flags are read after the loop. */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int fenv_loop(double y0, double c, int n, double th) {
  double y = y0;
  cq_theta(&y, th);
  feclearexcept(FE_ALL_EXCEPT);
  for (int i = 0; i < n; ++i)
    y = y * c;
  return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (cq_measure(y) > 0);
}
