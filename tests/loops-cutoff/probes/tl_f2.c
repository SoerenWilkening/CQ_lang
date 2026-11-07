/* tests/loops-cutoff probe (CR rules 9, 14), cq-wrr9t: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_f2.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_f2.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int r=5; for (unsigned i = c & 3; i < 3; i++) { if ((v >> i) & 1) { r = 2; goto C; } }
 if (b2) { r = 6; goto C; }
 for (unsigned i = (c >> 2) & 3; i < 3; i++) { if ((v >> i) & 2) { r = 3; goto C; } }
 r = 40;
C: return cq_measure(r);
}
