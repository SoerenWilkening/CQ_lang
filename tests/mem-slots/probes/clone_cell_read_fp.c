#include "CQ.h"
/* cq-qd05 k2b: the clone leaves an i64 rail in the caller cell (only int64 stores); the caller reads it as a double through a bitcast view. */
#include <stdint.h>
#include <string.h>
__attribute__((noinline)) static int g(int64_t x, double *ip, int64_t k) {
  if (x < k) { int64_t z = x & k; memcpy(ip, &z, 8); return 1; }
  int64_t z = x + 3; memcpy(ip, &z, 8);
  return 0;
}
double clone_cell_read_fp(int64_t x0, double th, int64_t k) {
  int64_t x = x0; cq_theta(&x, th);
  double ip;
  int r = g(x, &ip, k);
  return cq_measure(ip) + cq_measure(r);
}
