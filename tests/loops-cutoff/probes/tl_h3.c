/* tests/loops-cutoff probe (CR rules 9, 14), cq-0jawr: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_h3.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_h3.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; while (v & 1) { if (v&4) { r=9; goto C; } v >>= 1; n++; }
 if (b2) { r = 6+n; goto C; } 
 for (int i=c&1;i<3;i++) { if ((v>>i)&2) { r=20+i; goto C; } }
 r=30;
C: return cq_measure(r+256*n);
}
