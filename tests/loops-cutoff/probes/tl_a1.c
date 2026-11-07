/* tests/loops-cutoff probe (CR rules 9, 14), cq-fnkyd: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_a1.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_a1.c */
/* stpcpy skeleton: classical align; head loop with return; word loop; guarded byte loop, on scalars */
int f(unsigned c) {
  _Bool b0=1,b1=1,b2=1,b3=1;
  cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);
  unsigned v = b0|b1<<1|b2<<2|b3<<3;
  int r = 100;
  unsigned i = 0;
  if ((c & 1) == 0) {
    for (i = c & 3; i < 2; i++) {
      if (!((v >> i) & 1)) { r = i; goto out; }
    }
    while ((v & 3) != 0) { v >>= 1; r++; }
  }
  while (v & 1) { v >>= 1; r += 10; }
out:
  return cq_measure(r);
}
