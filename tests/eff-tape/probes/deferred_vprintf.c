/* Owner ruling 2026-11-12: vprintf's count is the lifted __cq_count_vsnprintf(0, 0, fmt, ap), no va_list copy added. */
#include <stdarg.h>
#include <stdio.h>
static int h(const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int r = vprintf(f, ap);
  va_end(ap);
  return r;
}
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = h("%d|", x);
  cq_measure(r);
  return 0;
}
// The count is lifted (a clone of the entry reading the va_list's rails); fails until cq-f0rb6 (a callee whose quantum
// input arrives only through memory is called as its own C symbol).
// CHECK-COUNT __cq_q_h_00: @cqrt_tape_effect_i32 0
// CHECK __cq_q_h_00: @cqrt_tape_effect_controlled(
// CHECK __cq_q_h_00: @__cq_q___cq_count_vsnprintf
