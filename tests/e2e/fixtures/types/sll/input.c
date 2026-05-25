/* tests/e2e/fixtures/types/sll/input.c — Per-type e2e fixture for the
 * `sll` (long long) ABI. PLAN §4.18 / M18. See ../c/input.c for the Q+Q
 * shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum long long x;             /* Pattern 1                         */
    quantum long long a = 3LL;       /* Pattern 2                         */
    quantum long long b = a;         /* Pattern 6 (no trace)              */
    quantum long long y = 7LL;       /* Pattern 2 - Q+Q operand           */
    quantum long long c = b + 2LL;   /* Pattern 4 (Q+C)                   */
    quantum long long d = b + y;     /* Pattern 3 (Q+Q)                   */
    (long long) c;                   /* Pattern 5                         */
    (long long) d;                   /* Pattern 5                         */
    (void) x;
    return 0;
}
