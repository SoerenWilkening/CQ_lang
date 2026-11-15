/* tests/loops-cutoff probe (CR rules 2, 14, 19; owner, cq-2z29a): a measured carried value's loop under a quantum arm: its exit test reads the trip's outcome, so it is a classical loop whose measurement and branch run unconditionally (rule 2; owner 2026-11-15, cq-amtcn).
 * Regenerate me_arm.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_arm.c -o me_arm.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
if (b3) { int n=0; while (v & 1) { n += cq_measure(v); v >>= 1; } return n+1; }
 return 0;
}
