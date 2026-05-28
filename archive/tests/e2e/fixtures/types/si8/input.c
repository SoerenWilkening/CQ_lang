/* tests/e2e/fixtures/types/si8/input.c — Per-type e2e fixture for the
 * `si8` (signed char) ABI. PLAN §4.18 / M18. See ../c/input.c for the
 * rationale on using disjoint-operand Q+Q rather than the float PLAN
 * template's `d = b + c` shape.
 */
#include <CQ.h>

int main(void) {
    quantum signed char x;             /* Pattern 1                       */
    quantum signed char a = 3;         /* Pattern 2                       */
    quantum signed char b = a;         /* Pattern 6 (no trace)            */
    quantum signed char y = 7;         /* Pattern 2 - Q+Q operand         */
    quantum signed char c = b + 2;     /* Pattern 4 (Q+C)                 */
    quantum signed char d = b + y;     /* Pattern 3 (Q+Q)                 */
    (signed char) c;                   /* Pattern 5                       */
    (signed char) d;                   /* Pattern 5                       */
    (void) x;
    return 0;
}
