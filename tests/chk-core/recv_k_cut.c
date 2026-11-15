/* tests/chk-core fixture, cq-wqr8p (CR rule 14, §1.4 "Received K"): g's loop runs at most 2 trips (x > 2 and bit i of 0xB);
 * e calls it through a pointer with CQ_K(e, 2), so its table clone runs at the received K 2 and a_K never fires. A clone
 * that cuts at trip 1 there (K 1 in place of the received 2) differs from C wherever C runs the second trip.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I <CQ_spec> recv_k_cut.c -o recv_k_cut.O1.ll;
 * opt -load-pass-plugin=<build>/pass/libCQLower.so -passes=cq-lower -S recv_k_cut.O1.ll -o recv_k_cut.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned g(unsigned x) {
  unsigned s = 1, i;
  for (i = 0; ((0xBu >> i) & 1) && x > 2; i++) { x -= 3; s = s * 5 + x; }
  return s * 16 + x;
}
unsigned (*volatile fp)(unsigned) = g;
CQ_K(e, 2)
unsigned e(unsigned x0, double th) { unsigned x = x0; cq_theta(&x, th); return cq_measure(fp(x)); }
