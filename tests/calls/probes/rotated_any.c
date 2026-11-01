/* cq-budv (117): the clone rotates x[i] in place at a variable offset (T3 kAnyCell): every rail the caller's runtime-length
 * slot array may hold is hit by a non-diagonal gate at the call (calls noteRotatedCells, mem::slotRailsMayHold).
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec rotated_any.c -o rotated_any.O1.ll */
#include <stdbool.h>
#include "CQ.h"
static __attribute__((noinline)) void rot_all(bool x[], int n, double t) {
  for (int i = 0; i < n; i++) cq_theta(&x[i], t);
}
int ra(int n, double t) {
  bool x[n];
  for (int i = 0; i < n; i++) x[i] = false;
  for (int i = 0; i < n; i++) cq_theta(&x[i], 0.5);
  rot_all(x, n, t);
  int m = 0;
  for (int i = 0; i < n; i++) m |= (int)cq_measure(x[i]) << i;
  return m;
}
