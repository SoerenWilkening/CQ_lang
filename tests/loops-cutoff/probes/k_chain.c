/* tests/loops-cutoff probe (owner ruling of 2026-11-15, the activation-counter cut; CR §1.4, rule 14, rule 19): a function
 * reached only through a pointer calls itself through that pointer under a quantum predicate, so its _t_ctl table clone
 * carries the depth counter, and the cut test is d < K with K the K the clone receives (2 here, the callee's own 4): the
 * third live _ctl activation is cut, on the circuit and in the C oracle alike. kc_one: a table call that is no recursion,
 * received K 1, never cut. Checked against the C program with and without CQ_K_ROLLED.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec k_chain.c -o k_chain.O1.ll */
#include "CQ.h"
CQ_K(kc_chain, 2)
CQ_K(kc_one, 1)
__attribute__((noinline)) static unsigned kt(unsigned x);
unsigned (*volatile pt)(unsigned) = kt;
__attribute__((noinline)) static unsigned kt(unsigned x) {
  if (x > 3) return pt(x - 3) * 2 + 1;
  return x;
}
unsigned kc_chain(unsigned x0, double th) {   /* depth (x + 2) / 3 activations: cut where it exceeds 2 */
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(pt(x));
}
__attribute__((noinline)) static unsigned ku(unsigned x) { return x * 3 + 1; }
unsigned (*volatile pu)(unsigned) = ku;
unsigned kc_one(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(pu(x) + pu(x + 1));
}
