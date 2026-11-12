/* Owner ruling 2026-11-12: fputws returns 0, or -1 where the lifted wcsrtombs reports an encoding error (musl
 * fputws.c). */
#include <stdio.h>
#include <wchar.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = 7;
  if (x & 1)
    r = fputws(L"a\xe9", stdout);
  else
    r = fputws(L"ab", stdout);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// The count is the lowered __cq_count_wcsrtombs reached with no quantum argument: its own symbol (rule 19, 162), reading ws
// from the slot on the bus; its result is the handle (rule 19 Results: zero-extended to the C i64).
// CHECK probe: = call i64 @__cq_count_wcsrtombs(ptr null, ptr %{{slot}}, i64 0, ptr null)
