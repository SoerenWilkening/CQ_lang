#include "CQ.h"
#include <stdio.h>
#include <stdlib.h>
/* cq-t8oo: a call after an abort under a quantum predicate of a function that prints directly (never
   rewritten): its output would precede the tape's. A loud stop. */
__attribute__((noinline)) void report(int r) { printf("r %d\n", r); }
int ord_callee(int c, int k) {
  int x = cq_theta_si32(c, 1.0);
  if (x == k) abort();
  int r = cq_measure_si32(x);
  report(r);
  return r;
}
