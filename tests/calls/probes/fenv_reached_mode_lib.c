/* tests/calls probe (cq-57ju): compiled with -frounding-math (musl's libm flags): fpexcept.ignore ops in the
 * dynamic mode. */
__attribute__((noinline)) double third(double x) { return x / 3.0 + 0.1; }
