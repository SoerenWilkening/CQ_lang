/* tests/e2e/fixtures/types/ul/input.c — Per-type e2e fixture for the
 * `ul` (unsigned long) ABI. PLAN §4.18 / M18.
 *
 * LP64-pinned trace; see ../sl/input.c for the target-dependence note
 * and ../c/input.c for the Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum unsigned long x;             /* Pattern 1                     */
    quantum unsigned long a = 3UL;       /* Pattern 2                     */
    quantum unsigned long b = a;         /* Pattern 6 (no trace)          */
    quantum unsigned long y = 7UL;       /* Pattern 2 - Q+Q operand       */
    quantum unsigned long c = b + 2UL;   /* Pattern 4 (Q+C)               */
    quantum unsigned long d = b + y;     /* Pattern 3 (Q+Q)               */
    (unsigned long) c;                   /* Pattern 5                     */
    (unsigned long) d;                   /* Pattern 5                     */
    (void) x;
    return 0;
}
