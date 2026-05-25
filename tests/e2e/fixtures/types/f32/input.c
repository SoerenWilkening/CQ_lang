/* tests/e2e/fixtures/types/f32/input.c — Per-type e2e fixture for the
 * `f32` (float) ABI. PLAN §4.18 / M18.
 *
 * Uses the literal PLAN template (`d = b + c`): float add is not
 * algebraically associative for the optimizer's purposes, so the
 * `b + (b + 2.5f)` chain survives stage 2 intact and reaches the IR
 * pass as two distinct `fadd` ops. Compare to the int fixtures which
 * use a disjoint Q+Q operand.
 */
#include <CQ.h>

int main(void) {
    quantum float x;             /* Pattern 1                             */
    quantum float a = 1.5f;      /* Pattern 2                             */
    quantum float b = a;         /* Pattern 6 (no trace)                  */
    quantum float c = b + 2.5f;  /* Pattern 4 (Q+C)                       */
    quantum float d = b + c;     /* Pattern 3 (Q+Q)                       */
    (float) d;                   /* Pattern 5                             */
    (void) x;
    return 0;
}
