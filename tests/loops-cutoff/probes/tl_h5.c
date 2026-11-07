/* tests/loops-cutoff probe (CR rules 9, 14), cq-b9sj7: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_h5.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_h5.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=0,n=0; if (c&1) { if (b0) { r=3; goto T; } while (v&1) { v>>=1; n++; if (v&4) goto C; } r=4; } else { while (v&2) { v>>=1; n+=2; if (v&8) { r=5; goto C; } } }
T: if (b1) { r+=64; goto C; } while (v&4) { v>>=1; r+=2; }
C: return cq_measure(r+256*n);
}
