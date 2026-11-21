/* cq-9ea1d reduced case: a quantum FP op raises flags inside a classical arm nested in another classical arm;
 * nothing reads the state between the inner and the outer join; it is read after the outer one (fetestexcept,
 * and the entry's return). */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
double gy;
static double qd(double x0) { double x = x0; cq_theta(&x, 0.0); return x; }

int e_f(int c, int d, double a) {
  feclearexcept(FE_ALL_EXCEPT);
  double y = qd(a);
  if (c) {
    if (d) {
      if (y > 1.0)
        y = y * 1e308;
    }
    gy = y;
  }
  return cq_measure(fetestexcept(FE_ALL_EXCEPT));
}
