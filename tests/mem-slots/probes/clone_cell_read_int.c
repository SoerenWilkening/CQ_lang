#include "CQ.h"
/* cq-qd05 k2: the clone leaves an f64 rail in the caller cell (51 merge: some arm stores a double); the caller reads it at i64 through a bitcast view. */
#include <stdint.h>
#include <string.h>
__attribute__((noinline)) static double g(double x, double *ip, int k, int64_t mask) {
  int64_t bits; memcpy(&bits, &x, 8);
  int e = (int)(bits >> 52) & 0x7ff;
  if (e < k) { int64_t z = bits & mask; memcpy(ip, &z, 8); return x; }
  *ip = x * 2.0;
  return x - x;
}
int64_t clone_cell_read_int(double x0, double th, int k, int64_t mask) {
  double x = x0; cq_theta(&x, th);
  double ip;
  double f = g(x, &ip, k, mask);
  int64_t b; memcpy(&b, &ip, 8);
  return cq_measure(b) + (int64_t)cq_measure(f);
}
