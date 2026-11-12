/* cq-yd85w (CR rule 16 noreturn; DECISIONS cq-tdqrq): an input on which the C program calls abort, _Exit, _exit or
 * __builtin_trap is in the domain and compared (the end, its status); before the fix the sampler dropped them all. */
#include "CQ.h"
#include <stdlib.h>
#include <unistd.h>
int f(int x0, int c) {
  int x = x0;
  cq_theta(&x, 0.5);
  if (c == 1) abort();
  if (c == 2) _Exit(3);
  if (c == 3) __builtin_trap();
  if (c == 4) _exit(5);
  return cq_measure(x + c);
}
