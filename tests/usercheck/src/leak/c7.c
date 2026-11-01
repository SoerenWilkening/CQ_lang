#include <stdint.h>
#include <string.h>
/* view read under a quantum predicate in the caller */
__attribute__((noinline)) static int g(int64_t x, double *ip) { int64_t z = x + 3; memcpy(ip, &z, 8); return 1; }
double c7(int64_t x0, double th) {
  int64_t x = x0; cq_theta(&x, th);
  double ip; int r = g(x, &ip);
  double a = 0.5;
  if (x > 5) a = ip * 2.0;
  return cq_measure(a) + r;
}
