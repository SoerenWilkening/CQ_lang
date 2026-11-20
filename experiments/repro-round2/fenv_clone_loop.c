/* cq-03rdt (GSL ode-initval2 rk2imp_apply): a classically bounded loop whose trips call, under a quantum
   condition, a function carrying the floating-point environment (its clone returns the new flags, rule 23),
   inside an outer classical loop; the flags are read after both loops. Before the fix every trip started
   from no flags (the loop carried none) and the read after the loop named the last trip's flags rail, which
   the loop's reverse had freed. */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double scale(double y, double c) { return y * c; }
int fenv_clone_loop(double y0, double c, int n, int m, double th) {
  double y = y0;
  cq_theta(&y, th);
  feclearexcept(FE_ALL_EXCEPT);
  for (int j = 0; j < m; ++j)
    for (int i = 0; i < n; ++i)
      if (y > 1.0)
        y = scale(y, c);
  return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (cq_measure(y) > 0);
}
