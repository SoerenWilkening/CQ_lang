#include "CQ.h"
/* cq-vxgm a1: the clone writes the caller's cell only when c (a classical condition); the caller cleans the
   old rail after the call, then the unwritten path measures it. Unimplemented until the clone copies out the
   old content on that path. */
__attribute__((noinline)) static void f(int v, int c, int *p) { if (c) *p = v + 1; }
int clone_partial_write(int x0, double th, int c) { int x = x0; cq_theta(&x, th); int s = x * 3; f(x, c, &s); return cq_measure(s); }
