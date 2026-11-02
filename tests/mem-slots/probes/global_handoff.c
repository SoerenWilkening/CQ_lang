#include "CQ.h"
/* cq-05pa (CR rules 18, 20; musl lgamma's @__signgam handed to __lgamma_r): a global slot object handed to a clone
   that writes it. The old content is the cell's current handle (rule 20), the clone's handle stays in the cell
   (kept: visible at exit); with a twin to run (the result dies here), it is copied out, the copy stored back, and
   the twin runs on the snapshot (rule 18 twin point). */
int sg;
static int sgi;
__attribute__((noinline)) static int g(int x, int *e) { *e = x * 3; return x + 1; }
__attribute__((noinline)) static int f(int x) { return g(x, &sgi) ^ 5; }
int global_handoff_internal(int a) { cq_theta(&a, 0.3); return cq_measure(f(a)); }
__attribute__((noinline)) static int f2(int x) { return g(x, &sg) ^ 5; }
int global_handoff_extern(int a) { cq_theta(&a, 0.3); return cq_measure(f2(a)); }
__attribute__((noinline)) static int rd(int y) { return sgi + y; }
int global_handoff_read(int a) { cq_theta(&a, 0.3); int r = f(a); return cq_measure(r) + cq_measure(rd(a)); }
