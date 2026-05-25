/* tests/e2e/fixtures/types/f64/input.c — Per-type e2e fixture for the
 * `f64` (double) ABI. PLAN §4.18 / M18.
 *
 * Uses the literal PLAN template — see ../f32/input.c for the
 * float-associativity note.
 */
#include <CQ.h>

int main(void) {
    quantum double x;             /* Pattern 1                            */
    quantum double a = 1.5;       /* Pattern 2                            */
    quantum double b = a;         /* Pattern 6 (no trace)                 */
    quantum double c = b + 2.5;   /* Pattern 4 (Q+C)                      */
    quantum double d = b + c;     /* Pattern 3 (Q+Q)                      */
    (double) d;                   /* Pattern 5                            */
    (void) x;
    return 0;
}
