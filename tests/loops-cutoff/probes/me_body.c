/* tests/loops-cutoff probe (CR rules 2, 14, 19; owner, cq-2z29a): a loop-carried value with a rail incoming is a rail in every trip. Clang -O1 tests b0 for `v & 1` at the loop's entry (a quantum arm) and `v & 2` on the carried v after the trip's cq_measure of it: that test reads the outcome and is classical (owner 2026-11-15, cq-amtcn), so the loop is a classical loop, one measurement per executed trip.
 * Regenerate me_body.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_body.c -o me_body.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; while (v & 1) { n += cq_measure(v); v >>= 1; }
 return n;
}
