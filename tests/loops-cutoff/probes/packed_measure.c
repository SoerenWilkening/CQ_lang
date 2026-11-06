/* tests/loops-cutoff probe (CR rules 2, 26): musl div's shape. A struct { int, int } returned coerced to one i64 is bound
 * field-wise, and cq_measure reads it whole. Regenerate packed_measure.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec packed_measure.c -o packed_measure.O1.ll */
#include "CQ.h"
#include <string.h>
typedef struct { int quot, rem; } pm_t;
__attribute__((noinline)) static pm_t pm(int a, int b) {
  pm_t r;
  r.quot = a + b;
  r.rem = a ^ b;
  return r;
}
int pm_whole(int x0, int y, double th) {
  int x = x0; cq_theta(&x, th);
  pm_t r = pm(x, y);
  long m[2] = {0, 0};
  memcpy(m, &r, sizeof r);
  cq_measure(m[0]);
  return 0;
}
