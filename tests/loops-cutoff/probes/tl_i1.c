/* tests/loops-cutoff probe (CR rules 9, 14), cq-7s0zo: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_i1.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_i1.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; while (v & 1) { if (v&4) { r=9; goto C; } v >>= 1; n++; }
 if (b2) { r = 6+n; goto C; } 
 { unsigned w=v; while (w & 2) { w>>=1; r++; if (b0) goto C; } r += 8; }
C: return cq_measure(r+256*n);
}
