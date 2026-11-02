#include "CQ.h"
/* cq-zndn (rules 9, 18, 20; musl __rem_pio2_large's y[] in the cases of switch (prec)): a clone writes caller
   cells under quantum predicates inside the arms of a classical branch; some arms leave a cell unwritten, one
   writes it unconditionally. Each path writes a cell at most once: f = select(p, v, old) on its own path. */
__attribute__((noinline)) static void f(int k, double v, double *y) {
  switch (k) {
  case 0: if (v > 1.0) y[0] = v * 2.0; else y[0] = -v; break;
  case 1: y[0] = v + 1.0; if (v < 0.5) y[1] = v; break;
  case 2: if (v != 0.0) { y[0] = v; y[1] = v * v; } break;
  default: break;
  }
}
double clone_cell_classical_arms(double x0, double th) {
  double x = x0; cq_theta(&x, th);
  double a[2] = {x * 3.0, 4.0}, b[2] = {x, 5.0}, c[2] = {6.0, x}, d[2] = {x + 7.0, x};
  f(0, x, a); f(1, x, b); f(2, x, c); f(3, x, d);
  return cq_measure(a[0] + a[1] + b[0] + b[1] + c[0] + c[1] + d[0] + d[1]);
}
