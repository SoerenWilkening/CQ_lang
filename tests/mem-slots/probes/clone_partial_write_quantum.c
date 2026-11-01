#include "CQ.h"
/* cq-vxgm: the clone writes the caller's cell only under a quantum predicate; the arm stores do not cover
   every path, so the select's other arm is the caller's old content, loaded before the copy-out. */
__attribute__((noinline)) static void f(int v, int *p) { if (v & 1) *p = v + 1; }
int clone_partial_write_quantum(int x0, double th) { int x = x0; cq_theta(&x, th); int s = x * 3; f(x, &s); return cq_measure(s + x); }
