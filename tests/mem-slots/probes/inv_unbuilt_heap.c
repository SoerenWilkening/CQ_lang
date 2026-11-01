#include "CQ.h"
#include <stdlib.h>
/* cq-p8r6 (CR rules 6, 18): as inv_update_void, the caller's cell in a heap block: outside the _inv<c> scope. */
static __attribute__((noinline)) void dbl(int *p, int n) { p[0] = p[0] * 3 + n; }
int inv_unbuilt_heap(int a0, double t, int n) {
  int *a = malloc(2 * sizeof(int));
  a[0] = a0;
  cq_theta(&a[0], t);
  dbl(a, n);
  int r = cq_measure(a[0]);
  free(a);
  return r;
}
