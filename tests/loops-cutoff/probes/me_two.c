/* tests/loops-cutoff probe (CR rules 2, 14; owner, cq-oiclq): two arms after a K-loop that also returns past them measure different values:
 * two cq_measure, two cqrt_measure, each once after the trips.
 * Regenerate me_two.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_two.c -o me_two.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; while (v & 1) { if (b3 && n==1) return 100; v >>= 1; n++; }
 if (b2) return cq_measure(n+1000) + 1;
 return cq_measure(v+2000) + 2;
}
