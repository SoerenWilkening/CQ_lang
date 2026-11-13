/* cq-jp8qu (owner ruling 2026-11-12 item 1: nothing is emitted for an unread result, except for a format that may hold
 * %n): printf's result is unread, but its %n target is written by the lifted __cq_count_snprintf(0, 0, fmt, args...),
 * musl's count, before the format entry goes to the tape (whose %n prints and writes nothing). Checked against the C
 * program by tests/eff-tape/percent_n_check.sh (heavy: the lifted printf_core). */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int n = -1;
  printf("%c%n", 'a' + (x & 1), &n);
  return cq_measure(n);
}
// CHECK probe: = call i32 @__cq_q___cq_count_snprintf_0000(ptr null, i64 0, ptr @.str, ptr %{{va}})
// CHECK probe: cqrt_tape_fmt(
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
