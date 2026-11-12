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
// The count is the lowered __cq_count_vsnprintf reached with no quantum argument: its own symbol (rule 19, 162: the all-zero
// clone coincides with it), which reads the va_list's rails from the bus. cq-f0rb6: musl vfprintf's va_copy of that va_list
// is memcpy(d, s, 24) (rule 16, 109), a bus copy, never the host intrinsic.
// CHECK-COUNT __cq_q_h_00: @cqrt_tape_effect_i32 0
// CHECK __cq_q_h_00: @cqrt_tape_effect_controlled(
// CHECK __cq_q_h_00: = call i32 @__cq_count_vsnprintf(ptr null, i64 0, ptr @.str, ptr %{{ap}})
// CHECK-COUNT __cq_vfprintf: @llvm.va_copy 0
