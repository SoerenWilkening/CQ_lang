/* tests/e2e/fixtures/types/sl/input.c — Per-type e2e fixture for the
 * `sl` (long) ABI. PLAN §4.18 / M18.
 *
 * `long`'s ABI width is target-dependent: i64 on LP64 (Linux/macOS
 * x86_64 + aarch64), i32 on LLP64 (Windows) and 32-bit targets
 * (TypeMap.cpp::irWidthSuffix). The expected.log here pins the LP64
 * trace; an LLP64 CI port will need a parallel golden — out of scope
 * for the dev machine where this fixture lives. PRD §"Target-dependence
 * of `long`".
 *
 * See ../c/input.c for the Q+Q shape rationale.
 */
#include <CQ.h>

int main(void) {
    quantum long x;             /* Pattern 1                              */
    quantum long a = 3L;        /* Pattern 2                              */
    quantum long b = a;         /* Pattern 6 (no trace)                   */
    quantum long y = 7L;        /* Pattern 2 - Q+Q operand                */
    quantum long c = b + 2L;    /* Pattern 4 (Q+C)                        */
    quantum long d = b + y;     /* Pattern 3 (Q+Q)                        */
    (long) c;                   /* Pattern 5                              */
    (long) d;                   /* Pattern 5                              */
    (void) x;
    return 0;
}
