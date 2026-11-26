/* tests/loops-cutoff probe (cq-p1olk; CR rule 14 case 2, region form): a header-tested quantum-exit K-loop whose header
 * switch also aborts, with a bus access in the body, so the body's trip-local predicate mints a flag over the header's
 * case equalities. The next trip's header test, evaluated after the trip's state advanced in the same output block, took
 * that flag back from the flag-reuse cache (cq-ct59d) although the header phi had been rebound: q_{j+1} = q_j & test(x_j),
 * so the trip after the quantum exit ran on and its classically chosen s += 100 reached s (x = 4, y = 3: 107, C 7).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec region_reuse.c -o region_reuse.O1.ll */
#include "CQ.h"
void abort(void);
int rr_g[8];
int rr(unsigned x0, double th, unsigned y) {
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 31;
  int s = 0;
  unsigned k = 0;
  while (x != 0) {
    if (x == 6)
      abort();
    rr_g[x & 7] += 1;
    if (k == (y & 3)) s += 100;
    s += (int)x;
    x >>= 1;
    k++;
  }
  return s;
}
