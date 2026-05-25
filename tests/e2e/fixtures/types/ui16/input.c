/* tests/e2e/fixtures/types/ui16/input.c — Per-type e2e fixture for the
 * `ui16` (unsigned short) ABI. PLAN §4.18 / M18. See ../c/input.c for
 * the Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum unsigned short x;             /* Pattern 1                    */
    quantum unsigned short a = 3;         /* Pattern 2                    */
    quantum unsigned short b = a;         /* Pattern 6 (no trace)         */
    quantum unsigned short y = 7;         /* Pattern 2 - Q+Q operand      */
    quantum unsigned short c = b + 2;     /* Pattern 4 (Q+C)              */
    quantum unsigned short d = b + y;     /* Pattern 3 (Q+Q)              */
    (unsigned short) c;                   /* Pattern 5                    */
    (unsigned short) d;                   /* Pattern 5                    */
    (void) x;
    return 0;
}
