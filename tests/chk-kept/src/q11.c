/* tests/chk-kept (CR rule 20 Allocation, §6 item 1; owner 2026-11-12 cq-mrdkr): fillc allocates calloc(n, 8) with n a rail
 * and no bound, so the allocation is made at K2 bytes and its kept predicate is or_i1(overflow, n*8 > K2), the overflow
 * and the compare undone at once. As q8: the call stays in an arm the C program does not take on most inputs, so the
 * _ctl clone's kept predicate stays live at exit where the C program never allocated. */
#include <stdlib.h>
unsigned long *sinkc;
__attribute__((noinline)) int fillc(unsigned long n) {
  unsigned long *p = calloc(n, 8);
  p[0] = n;
  sinkc = p;
  return (int)p[0];
}
int q11(long x0) {
  long x = x0;
  cq_theta(&x, 0.5);
  int r = 1;
  if ((unsigned long)x >= 0xfffffffffffffff0ul)
    r = fillc((unsigned long)x);
  return cq_measure(r);
}
