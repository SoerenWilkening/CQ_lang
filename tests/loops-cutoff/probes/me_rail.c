/* tests/loops-cutoff probe (CR rules 2, 14, 19; owner, cq-2z29a): one rail measured in a loop body: rule 2 makes the re-measurement a classical re-read, so f holds 2 with the final measure; rule 19 mints a controlled copy per cq_measure in the _ctl clone, so it holds K + 1.
 * Regenerate me_rail.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_rail.c -o me_rail.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; while (v & 1) { if (cq_measure(b1)) n += 2; v >>= 1; n++; }
 return cq_measure(n);
}
