/* Owner ruling 2026-11-12 (rule 16): printf's count read by the program is the lifted __cq_count_snprintf(0, 0, fmt,
 * args...), linked by driver/cq_entries.py's contract; the effect is a format entry with no result. */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = printf("%d|", x);
  cq_measure(r);
  return 0;
}
// CHECK probe: cqrt_tape_fmt(
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK probe: @__cq_q___cq_count_snprintf
