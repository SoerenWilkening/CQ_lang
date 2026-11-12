/* cq-xazgw: an entry returning a handle while a replayed table clone (other) shifts rail names from handles: the
 * driver must log the result's rail name (run.py writes __cqe_hret_names into the module it builds). */
#include "CQ.h"
__attribute__((noinline)) int in(int x) { return cq_measure(x) + 1; }
__attribute__((noinline)) int other(int x) { return x + 5; }
int a(int a, int k) { int (*p)(int) = k ? in : other; cq_theta(&a, 1.0); int r = p(a + 1); return r + cq_measure(a); }
