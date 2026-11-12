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
// The lifted entry: fails until cq-f0rb6 (clang passes ws through a slot; a callee whose quantum input arrives only
// through memory is called as its own C symbol).
// CHECK probe: @__cq_q___cq_count_wcsrtombs
