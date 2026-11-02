/* tests/calls probe (cq-4e6m; CR rules 18, 20, 21): a clone whose stores through a pointer formal include ones past
 * the caller's object on paths a classical argument never takes (musl __rem_pio2_large writing y[1], y[2] for
 * prec 0 into __rem_pio2f's double ty[1]): those stores write no cell (an access past an object is outside the
 * domain). Regenerate: clang -O1 store_past_object.c */
#include "CQ.h"
__attribute__((noinline)) void fill(double x, double *y, int prec) {
  switch (prec) {
  case 2: y[2] = x * 4.0; /* fallthrough */
  case 1: y[1] = x * 2.0; /* fallthrough */
  default: y[0] = x + 1.0;
  }
}
double sp_one(double a, double t) { double x = a; cq_theta(&x, t); double y[1]; fill(x, y, 0); return cq_measure(y[0]); }
