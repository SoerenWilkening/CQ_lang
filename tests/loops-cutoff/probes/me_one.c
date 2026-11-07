/* tests/loops-cutoff probe (CR rules 2, 14; owner, cq-oiclq): a measurement in a K-loop's exit arm, the loop also returning past it, runs once
 * after the trips on the arm's value merged across them. One cq_measure is one cqrt_measure.
 * Regenerate me_one.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_one.c -o me_one.O1.ll */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; while (v & 1) { if (b3 && n==1) return 100; v >>= 1; n++; }
 if (b2) { r = 6; goto C; }
 { unsigned w=v; while (w & 2) { w>>=1; r++; if (b0) goto C; } r += 8; }
C: return cq_measure(r+256*n);
}
