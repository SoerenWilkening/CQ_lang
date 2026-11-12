/* Owner ruling 2026-11-12 on cq-dbtpi (CR rule 16 Results): fclose, remove, rename return 0 (musl fclose.c, remove.c,
 * rename.c, every host operation succeeding); the effects have no result. */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = 5;
  if (x & 1)
    r = fclose(stdout) + remove("a") + 2 * rename("a", "b");
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 3
