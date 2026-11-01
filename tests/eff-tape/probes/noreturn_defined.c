#include "CQ.h"
#include <stdlib.h>
#include <stdio.h>
/* cq-wskg (rule 16): a call of a DEFINED noreturn function under a quantum predicate. A callee that
   aborts on every path with nothing before is abort_i1(pred), never the original call. */
__attribute__((noinline)) static void die(void) { abort(); }
__attribute__((noinline)) static void die_code(int c) { if (c) exit(c); abort(); }
__attribute__((noinline)) static void die2(int c) { die_code(c + 1); }
int p22(int i) {
  int q = cq_theta_si32(i, 1.0);
  if (q > 0) die();
  return cq_measure_si32(q);
}
int p22b(int i, int c) {
  int q = cq_theta_si32(i, 1.0);
  if (q < 3) die2(c);
  return cq_measure_si32(q);
}
