/* Owner ruling 2026-11-12: fwrite returns nmemb, 0 where size is 0 (musl fwrite.c). */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  size_t n = fwrite("abcd", x & 1, 2, stdout) + 10 * fwrite("abcd", 1, x & 3, stdout);
  cq_measure(n);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i64 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 2
