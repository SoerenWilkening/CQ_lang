/* tests/e2e/fixtures/typedef_uint32/input.c — Typedef-resolution e2e
 * fixture exercising `<stdint.h>`'s `uint32_t`. PLAN §4.19 / M19.
 *
 * On every supported target `uint32_t` resolves to `unsigned int`
 * (or equivalent), so Clang's canonical-type resolution must hand the
 * rewriter the same `unsigned int` it would see from the canonical
 * spelling. The acceptance proof is that expected.log here is
 * byte-identical to ../types/ui32/expected.log — if it weren't, the
 * typedef arm would have diverged from the canonical-type arm.
 *
 * See ../types/c/input.c for the Q+Q disjoint-operand shape rationale.
 */
#include <stdint.h>
#include <CQ.h>

int main(void) {
    quantum uint32_t x;             /* Pattern 1                          */
    quantum uint32_t a = 3u;        /* Pattern 2                          */
    quantum uint32_t b = a;         /* Pattern 6 (no trace)               */
    quantum uint32_t y = 7u;        /* Pattern 2 - Q+Q operand            */
    quantum uint32_t c = b + 2u;    /* Pattern 4 (Q+C)                    */
    quantum uint32_t d = b + y;     /* Pattern 3 (Q+Q)                    */
    (uint32_t) c;                   /* Pattern 5                          */
    (uint32_t) d;                   /* Pattern 5                          */
    (void) x;
    return 0;
}
