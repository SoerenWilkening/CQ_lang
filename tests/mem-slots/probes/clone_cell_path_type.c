#include "CQ.h"
/* cq-nyto (3), review c1: the clone stores the caller's cell as i64 on one classical path and as double on
   the other; the rail type the caller reads depends on the path: unimplemented. */
#include <stdint.h>
#include <string.h>
__attribute__((noinline)) static int g(int64_t x, double *ip, int c) {
  if (c) { int64_t z = x + 3; memcpy(ip, &z, 8); } else { *ip = (double)x; }
  return 1;
}
int64_t clone_cell_path_type(int64_t x0, double th, int c) {
  int64_t x = x0; cq_theta(&x, th);
  double ip; int r = g(x, &ip, c);
  int64_t b; memcpy(&b, &ip, 8);
  return cq_measure(b) + r;
}
