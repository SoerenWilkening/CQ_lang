/* tests/loops-cutoff probe, cq-9kcq S6 (CR §1.4 "Received K": a value other than all ones is the K of that activation,
 * in place of its own, whether smaller or larger; owner 2026-11-15): the cq-9kcq reproducer tk_f with the received K
 * above the callee's own. Each callee's address escapes, so it has a table clone; each entry calls it through a pointer
 * with CQ_K(entry, 6) (tk6_f, tk6_d) or CQ_K(entry, 2) (tk2_f), while the callee's own K is 4. The table clone runs
 * Krt trips. One C module: the C oracle runs the callee at the K its caller passes (cqo_rt.c k_recv).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec table_k6.c -o table_k6.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned kf(unsigned x, unsigned a) {   /* body form (05) */
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n;
}
__attribute__((noinline)) static unsigned kd(unsigned x, unsigned a) {   /* do ... while (150) */
  unsigned n = 0;
  do { x = x * a + 1; n += 2; } while (x > 9);
  return n;
}
unsigned (*volatile pf)(unsigned, unsigned) = kf;
unsigned (*volatile pd)(unsigned, unsigned) = kd;
CQ_K(tk6_f, 6)
CQ_K(tk6_d, 6)
CQ_K(tk2_f, 2)
unsigned tk6_f(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pf(x, a)); }
unsigned tk6_d(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pd(x, a)); }
unsigned tk2_f(unsigned x0, double th, unsigned a) { unsigned x = x0; cq_theta(&x, th); return cq_measure(pf(x, a)); }
