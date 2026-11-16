/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family FA: a noreturn arm behind a measurement in the trip of a quantum-exit K-loop.
 * Each entry is checked against its C program. At d5e32f61 f9_abort is an internal error (cq-njnmt); the K-static-copies lowering (4afda23b) leaked a rail.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_fa.c -o diff_fa.O1.ll */
#include "CQ.h"
#include <stdlib.h>
/* a noreturn arm in the trip */
unsigned f9_abort(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) {
    if (cq_measure(x & 0x80000000u)) abort();
    s += x; x >>= 1;
  }
  return cq_measure(s);
}
