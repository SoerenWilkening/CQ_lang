#include "CQ.h"
/* cq-hfah: the review repro (gate 2a taint-h3 p10) verbatim; host_global_cell.c has the variants. */
#include <stdio.h>
int A[4];
int cnt;
__attribute__((noinline)) void report(void) { printf("%d %d\n", A[1], cnt); }
int e13(int x, double t, int c) {
  A[1] = c;
  cnt = c * 2;
  int q = cq_theta_si32(x, t); A[0] = q;
  report();
  int r = cq_measure_si32(q);
  return r;
}
