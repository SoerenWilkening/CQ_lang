/* slice_4jok_bank_cell_from_hoisted.c — bd `test_C_libtooling-4jok`, THE TENTH
 * MEMBER OF THE COMPOSED ACCEPT SURFACE, and the one that says something about
 * how the surface was counted.
 *
 * ⚠ ROUND 3 TABULATED THIS PROGRAM AS DECLINING ON ALL FOUR OF ITS BINARIES and
 * concluded from it (its F-6) that bd `zujr` (L3)'s retirement trigger — *"the
 * day a bank cell can hold a TEMPLATE-minted rail"* — was still un-fired.  The
 * INDEPENDENT Rule-13 round 5 re-measured it on a composition built over a
 * different base and it is a MAIN -> COMPOSED **ACCEPT**.  So the surface is TEN
 * programs, not nine, and a "still empty" measurement of a gap is a fact about a
 * binary pair, never about the compiler (`CLAUDE.md` Rule 11).
 *
 * THE SHAPE, and it is the one where the two increments' clauses MEET INSIDE ONE
 * ITERATION rather than merely coexisting: the bank cell `b[i]` is WRITTEN from
 * the hoisted template rail `p = q*3` (bd `tu9q` (ii-d)'s subject) and READ in
 * the same body as the region's condition (bd `zujr` (L3)'s subject), beside the
 * carried handle `a` (bd `zujr`'s other clause).  Every other slice in this
 * family has the two clauses in different statements.
 *
 * ⚠ IT IS NOT A CLEARANCE FOR (L3)'s TRIGGER AND MUST NOT BE READ AS ONE.  Round
 * 5 also built two constructions that write a bank cell from the hoisted rail and
 * DECLINE on the composed binary at `cq rail bank: cell type rewrite failed on a
 * proven bank` — a fence that is NOT the `isInteriorTerminalHandle` (I1) ground
 * (L3)'s comment gives for itself.  The closure holds today for a reason other
 * than the stated one, which is `CLAUDE.md` L7's shape; it is filed as bd
 * `test_C_libtooling-a945` and is owed on any binary carrying bd `tu9q` P0+P3.
 *
 * ⚠ THIS PROGRAM DECLINES ON THE PRE-LANDING COMPILER (`cq-opt` 8280ea8d…) at
 * the bd `s82e` string, so the golden is non-vacuous for this landing.
 */
#include "CQ.h"
int slice(int u) {
    int q = u; cq_theta(&q, 0.5);
    int p = q * 3;
    bool b[3];
    int a = 5;
    for (int i = 0; i < 3; i++) {
        b[i] = (p >> i) & 1;
        if (b[i]) cq_phi(0.2);
        if (a >= 3) a -= 3;
    }
    cq_theta(&q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
/* ⚠ `(void)slice(4); return 0;` RATHER THAN `return slice(4);`, AND IT IS NOT
 * COSMETIC.  In THIS program `a` never becomes quantum — `if (a >= 3) a -= 3;`
 * is classical control on a classical value — so `cq_measure(a)` lowers to the
 * literal (bd `21mg`: a measure of a never-quantum value is the value, no symbol
 * and NO TRACE LINE).  The function therefore returns 2, the process exits 2,
 * and `run_slice.sh`'s `set -o pipefail` fails the slice with EMPTY OUTPUT and no
 * diff — a red that looks nothing like what it is.  Every other slice in this
 * family measures only quantum handles and returns 0 BY LUCK.  The convention
 * here is the tree's existing one (`slice_control_inplace_ry_loop_leak.c`); the
 * `cq_*` calls are not pure, so nothing in the traced body is DCE'd by the
 * discarded result — MEASURED: the golden is byte-identical at 34 lines before
 * and after this change. */
int main(void) { (void)slice(4); return 0; }
