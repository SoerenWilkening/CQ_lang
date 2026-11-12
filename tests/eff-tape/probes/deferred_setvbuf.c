/* Owner ruling 2026-11-12 on cq-dbtpi (CR rule 16 Results): setvbuf returns 0, -1 for a type outside {0, 1, 2} (musl
 * setvbuf.c); with a rail type, a quantum compare and select. The effect has no result. */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = setvbuf(stdout, 0, x, 0);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 1
// CHECK probe: @cq_template_icmp_ugt_i32_hl(
