/* tests/loops-cutoff probe (CR rules 9, 14), cq-kooou: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_a4.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_a4.c */
/* classical path selects whether loop A runs; tail loop reached from both; edge skips under quantum only outside */
int f(unsigned c) {
  _Bool b0=1,b1=1,b2=1,b3=1;
  cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);
  unsigned v = b0|b1<<1|b2<<2|b3<<3;
  int r = 0, n = 0;
  if (c & 1) {
    while (v & 1) { if (b1 && n==1) { r = 11; goto C; } v >>= 1; n++; }
  } else if (b1) {
    r = 12; goto C;
  }
  /* tail shared */
  if (b2) { r = 13; goto C; }
  while (v & 2) { v >>= 1; n++; if (c & 2) { if (b3) { r = 14 + n; goto C; } } }
  r = 90;
C:
  return cq_measure(r * 10 + n);
}
