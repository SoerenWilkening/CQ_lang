/* tests/e2e/fixtures/types/i1/input.c — Per-type e2e fixture for the
 * i1 (_Bool) ABI. PLAN §4.18 / M18.
 *
 * Patterns covered: 1 (uninit), 2 (literal init), 5 (measure).
 *
 * Patterns 3 (Q+Q add), 4 (Q+C add), and 6 (rebind, when b is later
 * used) are NOT applicable for i1: clang lowers `_Bool + _Bool` and
 * `_Bool + literal` to bitwise `or i8` / `and i8` (since the result is
 * the same on bools), and any later load from a `_Bool` storage location
 * inserts `and i8, 1` for bit-canonicalization. The cq-lowering IR pass
 * has no template for `or i8`/`and i8` in tainted context (PRD §"Type
 * map" — only `add` is wired for i1), so those patterns cannot reach the
 * runtime. This fixture documents the realistic i1 coverage.
 */
#include <CQ.h>

int main(void) {
    quantum _Bool x;              /* Pattern 1: uninit -> alloc(0)         */
    quantum _Bool a = (_Bool)1;   /* Pattern 2: literal init               */
    (_Bool) a;                    /* Pattern 5: measure                    */
    (void) x;
    return 0;
}
