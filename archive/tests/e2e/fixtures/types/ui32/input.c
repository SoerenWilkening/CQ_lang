/* tests/e2e/fixtures/types/ui32/input.c — Per-type e2e fixture for the
 * `ui32` (unsigned int) ABI. PLAN §4.18 / M18. See ../c/input.c for the
 * Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum unsigned int x;             /* Pattern 1                      */
    quantum unsigned int a = 3u;        /* Pattern 2                      */
    quantum unsigned int b = a;         /* Pattern 6 (no trace)           */
    quantum unsigned int y = 7u;        /* Pattern 2 - Q+Q operand        */
    quantum unsigned int c = b + 2u;    /* Pattern 4 (Q+C)                */
    quantum unsigned int d = b + y;     /* Pattern 3 (Q+Q)                */
    (unsigned int) c;                   /* Pattern 5                      */
    (unsigned int) d;                   /* Pattern 5                      */
    (void) x;
    return 0;
}
