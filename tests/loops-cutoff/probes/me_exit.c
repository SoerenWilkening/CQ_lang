/* tests/loops-cutoff probe (owner 2026-11-15, cq-amtcn; CR rules 2, 8, 14): exit tests on a measured loop-carried value.
   ex_pre: the header tests v & 4 BEFORE the trip's cq_measure of v: that test reads the unmeasured carried rail and stays
   quantum (a K-loop with a_K); the latch test (v < 2) reads the trip's outcome and is classical.
   ex_conj: (v & 1) after the trip's measurement is classical, beside the quantum !b2: a classical conjunct (owner ruling Q10).
   ex_arm: inside the quantum arm b2 every exit reads the outcome: a classical loop (no K, no a_K) whose measurement and
   branch run unconditionally (rule 2), one cqrt_measure per executed trip.
   Regenerate me_exit.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec me_exit.c -o me_exit.O1.ll */
#include "CQ.h"
int ex_pre(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; for (;;) { if (v & 4) break; n += cq_measure(v); v >>= 1; if (v < 1) break; }
 return n;
}
int ex_conj(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3|16;
int n=0; do { n += cq_measure(v); v >>= 1; } while ((v & 1) && !b2);
 return n;
}
int ex_arm(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=c; if (b2) { do { n += cq_measure(v) + 1; v >>= 1; } while (v & 1); n += 10; }
 return n;
}
