/* tests/e2e/fixtures/types/si16/input.c — Per-type e2e fixture for the
 * `si16` (short) ABI. PLAN §4.18 / M18. See ../c/input.c for the Q+Q
 * shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum short x;             /* Pattern 1                             */
    quantum short a = 3;         /* Pattern 2                             */
    quantum short b = a;         /* Pattern 6 (no trace)                  */
    quantum short y = 7;         /* Pattern 2 - Q+Q operand               */
    quantum short c = b + 2;     /* Pattern 4 (Q+C)                       */
    quantum short d = b + y;     /* Pattern 3 (Q+Q)                       */
    (short) c;                   /* Pattern 5                             */
    (short) d;                   /* Pattern 5                             */
    (void) x;
    return 0;
}
