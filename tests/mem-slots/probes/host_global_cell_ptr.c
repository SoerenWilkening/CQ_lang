#include "CQ.h"
#include <stdio.h>
/* cq-hfah (CR rule 20 per cell): the host cell A[1] (no handle ever stored there) read by a callee through a
   pointer: report_ptr is handed a pointer to an object holding a handle (A[0]), so taint lifts it; its read
   of p[1] is a host load of the global's own memory. Main stopped on it (a classical load from a slot cell). */
int A[4];
__attribute__((noinline)) void report_ptr(const int *p) { printf("%d\n", p[1]); }
int via_ptr(int x, double t, int c) {
  A[1] = c + 1;
  int q = cq_theta_si32(x, t); A[0] = q;
  report_ptr(A);
  return cq_measure_si32(q);
}
