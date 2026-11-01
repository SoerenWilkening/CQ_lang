#include <stdint.h>
#include <string.h>
/* view read, value not measured, only used in a comparison; rail kept */
__attribute__((noinline)) static int g(int64_t x, double *ip) { int64_t z = x + 3; memcpy(ip, &z, 8); return 1; }
int c8(int64_t x0, double th) {
  int64_t x = x0; cq_theta(&x, th);
  double ip; int r = g(x, &ip);
  int q = ip > 1.0;
  return cq_measure(q) + r + (int)cq_measure(x);
}
