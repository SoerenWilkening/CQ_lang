#include "CQ.h"
#include <stdlib.h>
/* cq-woqja (rule 16 noreturn; owner rulings 2026-11-11 Q7, 2026-11-14 scope of Q7 and Q1): an all-classical call of a
   DEFINED internal noreturn helper after an event inside the lowered code. Its exit is the effect entry exit under a true
   seed, then abort_i1 of the seed, never the host call that ends the shot before the earlier abort flag is read. */
__attribute__((noinline)) static void quit(void) { exit(3); }
__attribute__((noinline)) static void mid(int c) { quit(); }
int caller(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) quit();
  return cq_measure(b);
}
int chain(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) mid(c);
  return cq_measure(b);
}
