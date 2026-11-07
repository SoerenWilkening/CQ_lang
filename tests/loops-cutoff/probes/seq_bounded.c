/* tests/loops-cutoff probe, cq-cytmk (CR rules 5, 14): two classically bounded loops with a quantum break in sequence: the second is in the
 * first's classical exit arm, its reverse runs inside the first's mirror.
 * Regenerate seq_bounded.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec seq_bounded.c -o seq_bounded.O1.ll */
#include "CQ.h"
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=5; unsigned i; for (i = 0; i < 3; i++) { if ((v >> i) & 1) { r = 2; goto C; } }
 for (i = 0; i < 3; i++) { if ((v >> i) & 2) { r = 3; goto C; } }
 r = 40;
C: return cq_measure(r);
}
