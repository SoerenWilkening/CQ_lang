/* tests/e2e/fixtures/typedef_int8/input.c — Typedef-resolution e2e
 * fixture exercising `<stdint.h>`'s `int8_t`. PLAN §4.19 / M19.
 *
 * On every supported target `int8_t` is `typedef signed char int8_t;`
 * (or equivalent), so Clang's canonical-type resolution must hand the
 * rewriter the same `signed char` it would see from the canonical
 * spelling. The acceptance proof is that expected.log here is
 * byte-identical to ../types/si8/expected.log — if it weren't, the
 * typedef arm would have diverged from the canonical-type arm.
 *
 * See ../types/c/input.c for the Q+Q disjoint-operand shape rationale.
 */
#include <stdint.h>
#include <CQ.h>

int main(void) {
    quantum int8_t x;             /* Pattern 1                            */
    quantum int8_t a = 3;         /* Pattern 2                            */
    quantum int8_t b = a;         /* Pattern 6 (no trace)                 */
    quantum int8_t y = 7;         /* Pattern 2 - Q+Q operand              */
    quantum int8_t c = b + 2;     /* Pattern 4 (Q+C)                      */
    quantum int8_t d = b + y;     /* Pattern 3 (Q+Q)                      */
    (int8_t) c;                   /* Pattern 5                            */
    (int8_t) d;                   /* Pattern 5                            */
    (void) x;
    return 0;
}
