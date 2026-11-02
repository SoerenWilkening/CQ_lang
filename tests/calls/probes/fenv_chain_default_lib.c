/* tests/calls probe (cq-4e6m): compiled with -frounding-math (musl's libm flags): fpexcept.ignore ops in the
 * dynamic mode. */
__attribute__((noinline)) double third(double x) { return x / 3.0 + 0.1; }
__attribute__((noinline)) void split(double x, double *y) { y[0] = third(x); y[1] = x * 0.5; }
