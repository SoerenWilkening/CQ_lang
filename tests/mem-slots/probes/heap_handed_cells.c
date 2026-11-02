#include "CQ.h"
/* cq-e5lj (CR rule 20: classified over all accesses in the whole program): a heap block this function only hands
   to clones takes its cell size from their accesses; main stopped at "never loads or stores". */
#include <stdlib.h>
__attribute__((noinline)) static void put(long *p, long v) { p[1] = v; }
__attribute__((noinline)) static long get(long *p) { return p[1]; }
long heap_pass(long x0, double th) {
  long *p = malloc(4 * sizeof(long));
  long x = x0; cq_theta(&x, th);
  put(p, x);
  long r = cq_measure(get(p));
  free(p);
  return r;
}
