/* Owner ruling 2026-11-12: fputwc, putwc, putwchar return the argument, or WEOF where the lifted wctomb fails (musl
 * fputwc.c; in musl's C locale 0xe9 does not encode). */
#include <stdio.h>
#include <wchar.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  wint_t r = fputwc((wchar_t)(x & 0xff), stdout);
  wint_t s = putwchar(L'A' + (x & 1));
  cq_measure(r);
  cq_measure(s);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK probe: @__cq_q___cq_count_wctomb
