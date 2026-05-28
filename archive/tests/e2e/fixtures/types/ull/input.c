/* tests/e2e/fixtures/types/ull/input.c — Per-type e2e fixture for the
 * `ull` (unsigned long long) ABI. PLAN §4.18 / M18. See ../c/input.c
 * for the Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum unsigned long long x;             /* Pattern 1                */
    quantum unsigned long long a = 3ULL;      /* Pattern 2                */
    quantum unsigned long long b = a;         /* Pattern 6 (no trace)     */
    quantum unsigned long long y = 7ULL;      /* Pattern 2 - Q+Q operand  */
    quantum unsigned long long c = b + 2ULL;  /* Pattern 4 (Q+C)          */
    quantum unsigned long long d = b + y;     /* Pattern 3 (Q+Q)          */
    (unsigned long long) c;                   /* Pattern 5                */
    (unsigned long long) d;                   /* Pattern 5                */
    (void) x;
    return 0;
}
