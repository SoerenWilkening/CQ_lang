/* tests/loops-cutoff probe (cq-xec3y; CR rules 9, 14): musl jnf's shape. Two K-loops in exclusive quantum arms exit
 * into one join. The join phi of b: the first loop leaves b as it is (its exit edge reads b, the start of its own carried u, so
 * that unit binds the phi), the second loop gives the exit value of the b it carries from the same start. The second unit
 * merges its exit value into the first unit's binding. Checked §6 against its own C program (cqcheck user). Regenerate join_earlier.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec join_earlier.c -o join_earlier.O1.ll */
#include "CQ.h"
int je_start(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = x & 3, b = (x >> 2) & 7, u = b, v = 1;
  if (!((x >> 5) & 1)) {
    for (unsigned i = n; i > 0; i--) { unsigned w = v * i + u; u = v; v = w; }
  } else {
    for (unsigned i = n; i > 0; i--) { unsigned t = b; b = b * 5 + u; u = t + i; }
  }
  return cq_measure(b * 64 + u * 4 + v);
}
