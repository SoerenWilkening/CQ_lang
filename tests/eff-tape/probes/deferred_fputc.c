/* Owner ruling 2026-11-12: fputc, putc, putchar return the argument as unsigned char (musl fputc.c, putc.h). */
#include <stdio.h>
int probe(int x) {
  cq_theta(&x, 0.3);
  int r = putchar(x + 200) + fputc(x, stdout) + putc(x - 1, stdout);
  cq_measure(r);
  return 0;
}
// CHECK-COUNT probe: @cqrt_tape_effect_i32 0
// CHECK-COUNT probe: @cqrt_tape_effect_controlled( 3
