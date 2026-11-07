/* tests/loops-cutoff probe, cq-tac1 (CR rules 8, 14): the same in a K-loop's exit arm: an arm's edge condition `c || q` is read whole.
 * Regenerate arm_test.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec arm_test.c -o arm_test.O1.ll */
#include "CQ.h"
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; while (v&1) { v>>=1; n++; if (b3) { r=1; if (c&1) goto D; else goto C; } }
 if (c&2) { if (b2) { r=2; goto C; } while (v&2) { v>>=1; r+=2; if (v&1) goto D; } }
 r+=16;
C: r+=32; goto E;
D: r+=64;
E: return cq_measure(r+256*n);
}
