/* Owner ruling 2026-11-12: puts and fputs return 0 (musl puts.c, fputs.c, every write succeeding); the effects have
 * no result. */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = 5;
  if (x & 1)
    r = puts("a") + fputs("b", stdout);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 2
