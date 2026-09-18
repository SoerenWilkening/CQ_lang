/* slice_predmux_classical_table.c — bd test_C_libtooling-fn1q increment 4
 * (PredMux E4's CLASSICAL const-table read). The bead's headline over-decline,
 * end to end: two classical tables indexed by the loop counter, read inside a
 * tainted-condition value arm.
 *
 * Before this increment the rolled form declined
 * `cq controlled lowering: control flow under quantum control` at `gate=E4-gep`,
 * because E4 admitted a `getelementptr` only as the address of a claimable QROM
 * read — and QROM refuses this one at its index-TAINT gate, which is correct:
 * the index here is the CLASSICAL loop counter, so this is not a QROM read at
 * all. The table values stay classical and occupy the `_hl` literal slot of the
 * mixed Q+C templates that consume them.
 *
 * ⚠ "nothing is allocated onto a rail for them" is what this line used to say and
 * it is true of THIS program, not in general (Rule-13 round 1 R4-P2-2): a table
 * value used as an ARM OF THE MERGE is materialised on a rail by the ordinary 4.4
 * data mux, exactly as a literal arm is. Sound, and not the §5.2 hazard, which is
 * about the operand slot of a mixed op.
 *
 * THE ADMISSION IS PROOF-GATED (owner ruling 2026-09-23): the flatten hoists the
 * loads out of the arm, so they must not fault where the source did not perform
 * them. `isDereferenceableAndAlignedInLoop` proves exactly that, per iteration.
 * An unprovable index keeps the old decline — see
 * control_predmux_reject_classical_table_unbounded_index.ll.
 *
 * ⚠ THE TABLES ARE MUTABLE (`int`, not `const`) ON PURPOSE. The in-loop proof arm
 * does not require immutability; the loop-free arm does. Making these `const`
 * would move the slice onto the other arm without changing its output, and the
 * blind spot would be invisible.
 */
#include "CQ.h"

int g_z[3] = {1, 2, 3};
int g_p[3] = {3, 2, 1};

static int slice(void) {
    int Z = 5, P = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(0, 0.5);
        if (q > 2) { Z -= g_z[i]; P += g_p[i]; }
    }
    return cq_measure(Z) + cq_measure(P);
}

int main(void) { (void)slice(); return 0; }
