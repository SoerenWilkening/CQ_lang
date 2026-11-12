/* Owner ruling 2026-11-12 on cq-dbtpi (CR rule 16 Results): fseek returns 0, -1 for a whence outside {0, 1, 2} (musl
 * fseek.c __fseeko_unlocked); with a rail whence, a quantum compare and select. The effects have no result. */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = fseek(stdout, x, 0) + 2 * fseek(stdout, x, 3) + 4 * fseek(stdout, 0, x);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 3
// CHECK probe: @cq_template_icmp_ugt_i32_hl(
// CHECK probe: @cq_template_select_i32_
