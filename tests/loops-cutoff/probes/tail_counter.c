/* tests/loops-cutoff probe, cq-hl4d7 (CR rules 9, 14): a loop's counter test read after the loop is its exit value, a rail: a select on it is one select.
 * Regenerate tail_counter.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec tail_counter.c -o tail_counter.O1.ll */
#include "CQ.h"
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; int i=0; for (;i<2;i++) { if ((v>>i)&1) { r=1; goto C; } }
 if (b2) { r = 6; goto C; } 
 for (i=0;i<2;i++) { if (b3) { r=3; goto C; } r++; }
C: return cq_measure(r);
}
