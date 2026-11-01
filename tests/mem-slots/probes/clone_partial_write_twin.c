#include "CQ.h"
/* cq-vxgm b1: as clone_partial_write, with a twin (the caller reads x after the call): the twin's slotOut
   is the old rail on the unwritten path (dirty + double free). Unimplemented. */
__attribute__((noinline)) static void f(int v, int c, int *p) { if (c) *p = v + 1; }
int clone_partial_write_twin(int x0, double th, int c) { int x = x0; cq_theta(&x, th); int s = x * 3; f(x, c, &s); return cq_measure(s + x); }
