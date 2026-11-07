/* tests/loops-cutoff probe (CR rules 2, 14, 19; owner, cq-2z29a): an exit arm's measurement inside an outer classical loop runs once per outer trip, after the inner loop's trips.
 * Regenerate me_outer.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_outer.c -o me_outer.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int t=0; for (unsigned k=0;k<2+(c&1);k++) { unsigned w=v|1; int n=0; do { if (b3 && n==1) { t+=100; goto N; } w>>=1; n++; } while (w & 1); t += cq_measure(n+k); N: ; v ^= c; }
 return t;
}
