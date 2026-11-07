#include "CQ.h"
/* K-loop variant of cq-wrr9t: unbounded scans behind the cleanup-dest switch, a quantum tail arm, c choosing the start. Exercises outsideEdge. */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=5; { unsigned i = c&1, w=v; while (w & 8) { if (w & 1) { r = 2; goto C; } w >>= 1; i++; } }
 if (b2) { r = 6; goto C; }
 { unsigned i = (c>>1)&1, w=v; while (w & 4) { if (w & 2) { r = 3+i; goto C; } w >>= 1; } }
 r = 40;
C: return cq_measure(r);
}
