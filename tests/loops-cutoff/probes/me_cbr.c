/* tests/loops-cutoff probe (CR rules 2, 8, 14; owner cq-47f8h; beads cq-v8cn7, cq-1ye9c): a cq_measure behind a
   classical branch. A purely classical condition is always a classical branch (rule 8), so the measurement runs only
   where the classical arguments take it, on both sides; only a quantum arm's measurement runs unconditionally (rule 2).
   h: loop-invariant w measured behind (c & 1) in a K-loop with a quantum exit: the site runs once per trip, behind its
   `br`; bit 3 of v is b3, so trip 3 is never reached and its execution is the site C reaches on trips 0 to 2.
   g: the same branch without a loop.
   run_probes.py MUTANTS: a trip that measures another register (v), every trip's measurement hoisted above its
   classical `br`, and g's measurement hoisted above its classical `br`, are rejected.
   Regenerate me_cbr.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec me_cbr.c -o me_cbr.O1.ll */
#include "CQ.h"
int h(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
unsigned w = b0|b2<<1;
int n=0; while ((v & 1) && !b3) { if (c & 1) n += cq_measure(w); v >>= 1; n++; }
 return n;
}
int g(unsigned c) { _Bool b0=1,b1=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);unsigned w = b0|b1<<1;
int n=0; if (c & 1) n += cq_measure(w); n++;
 return n;
}
