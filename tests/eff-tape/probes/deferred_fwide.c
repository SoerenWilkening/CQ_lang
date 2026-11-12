/* Owner ruling 2026-11-12 on cq-dbtpi: fwide's result is host state (the stream's orientation), so the program reads
 * the entry's rail, unchanged (ABI 1.11, Q2). */
#include <stdio.h>
#include <wchar.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = fwide(stdout, x);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 1
