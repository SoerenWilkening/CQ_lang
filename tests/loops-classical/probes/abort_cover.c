/* tests/loops-classical probe (cq-0u5ti, CR rules 8, 14; GMP mpn_mul_fft_decompose): an abort test under a classical
 * test before a classically bounded loop gives the trip's blocks the classical structure `a ? !b : 1`, no literal. In
 * the trip a quantum branch's arm walked first holds a classical branch whose arms meet the other quantum arm at the
 * latch: the arms' edge facts must cover the fact of the block they leave from, or the rejoin is not built and the latch
 * has no back edge. Regenerate abort_cover.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec abort_cover.c -o abort_cover.O1.ll */
#include "CQ.h"
int g;
int ac_ret(int x0, double th, int n, int a, int b, int c) {
  int x = x0;
  cq_theta(&x, th);
  if (a < n) {
    g = a;
    if (b > a)
      return 0;
  }
  int s = 0;
  if (x != 7)
    for (int i = 0; i < n; i++) {
      if (x > i) {
        cq_phi(0.25);
        s += x;
      } else if (c) {
        g = i;
      }
    }
  return cq_measure(s);
}
