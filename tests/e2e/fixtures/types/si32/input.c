/* tests/e2e/fixtures/types/si32/input.c — Per-type e2e fixture for the
 * `si32` (int) ABI. PLAN §4.18 / M18. See ../c/input.c for the Q+Q
 * shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum int x;             /* Pattern 1                               */
    quantum int a = 3;         /* Pattern 2                               */
    quantum int b = a;         /* Pattern 6 (no trace)                    */
    quantum int y = 7;         /* Pattern 2 - Q+Q operand                 */
    quantum int c = b + 2;     /* Pattern 4 (Q+C)                         */
    quantum int d = b + y;     /* Pattern 3 (Q+Q)                         */
    (int) c;                   /* Pattern 5                               */
    (int) d;                   /* Pattern 5                               */
    (void) x;
    return 0;
}
