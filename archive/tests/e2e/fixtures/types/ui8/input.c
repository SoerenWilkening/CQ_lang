/* tests/e2e/fixtures/types/ui8/input.c — Per-type e2e fixture for the
 * `ui8` (unsigned char) ABI. PLAN §4.18 / M18. See ../c/input.c for the
 * Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum unsigned char x;             /* Pattern 1                     */
    quantum unsigned char a = 3;         /* Pattern 2                     */
    quantum unsigned char b = a;         /* Pattern 6 (no trace)          */
    quantum unsigned char y = 7;         /* Pattern 2 - Q+Q operand       */
    quantum unsigned char c = b + 2;     /* Pattern 4 (Q+C)               */
    quantum unsigned char d = b + y;     /* Pattern 3 (Q+Q)               */
    (unsigned char) c;                   /* Pattern 5                     */
    (unsigned char) d;                   /* Pattern 5                     */
    (void) x;
    return 0;
}
