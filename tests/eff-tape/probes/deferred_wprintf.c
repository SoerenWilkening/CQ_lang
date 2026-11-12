/* Owner ruling 2026-11-12: wprintf's count is the bundle's __cq_count_wprintf (wprintf_core on a discarding FILE). */
#include <wchar.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = wprintf(L"%d|", x);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK probe: @__cq_q___cq_count_wprintf
