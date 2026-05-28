/* tests/e2e/fixtures/types/c/input.c — Per-type e2e fixture for the
 * `c` (plain `char`, signed on x86_64-linux) ABI. PLAN §4.18 / M18.
 *
 * Patterns covered: 1, 2, 3, 4, 5, 6. The Q+Q add uses a separately
 * allocated quantum operand `y` (rather than `d = b + c` as in the
 * float PLAN template) so the optimizer cannot algebraically fuse
 * `b + (b + lit)` into `2b + lit` — integer add IS associative for
 * the optimizer's purposes, unlike float add, and the fused `shl`
 * would have no template in tainted context. Pattern 6 invariant:
 * `b` shares `a`'s handle; the trace shows h1 (i.e. `a`) on the LHS
 * of both add lines, never an h<n> for `b` itself.
 */
#include <CQ.h>

int main(void) {
    quantum char x;             /* Pattern 1                              */
    quantum char a = 'A';       /* Pattern 2 ('A' == 65)                  */
    quantum char b = a;         /* Pattern 6 (no trace)                   */
    quantum char y = 'B';       /* Pattern 2 ('B' == 66) - Q+Q operand    */
    quantum char c = b + 2;     /* Pattern 4 (Q+C); b -> a's handle       */
    quantum char d = b + y;     /* Pattern 3 (Q+Q); b -> a's handle       */
    (char) c;                   /* Pattern 5                              */
    (char) d;                   /* Pattern 5                              */
    (void) x;
    return 0;
}
