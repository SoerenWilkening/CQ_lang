/* Owner ruling 2026-11-12 on cq-dbtpi (CR rule 16 Signal table): raise's result is 0 under every candidate flag and
 * musl's value under the complement branch, 0 for 0 <= sig <= 64, else -1 (musl raise.c, tkill); the complement's
 * effect entry has no result. */
#include <signal.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = raise(x);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 1
// CHECK probe: @cq_template_icmp_ugt_i32_hl(
