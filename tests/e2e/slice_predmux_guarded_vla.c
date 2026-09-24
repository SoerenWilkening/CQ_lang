/* slice_predmux_guarded_vla.c — bd xdu2.8: a CLASSICAL runtime-VLA read under
 * quantum control whose in-bounds proof holds only under the CLASSICAL conjunct
 * `k < m` of the arm's own condition.
 *
 * clang -O1 sinks `p[k]` into the arm; PredMux flattens the arm and would
 * speculate the read to the region entry, where `k < m` is not in force. The
 * read is admitted because the classical conjunct proves `k < extent`, and it is
 * emitted through `select (k <u m), &p[k], &cq.guarded.read.zero`, so the
 * speculated read is in bounds on every path. The value off the arm feeds only
 * the boolean-algebra merge whose predicate is false there.
 *
 * Two activations, so the golden pins BOTH paths: k = 1 < m = 3 (the literals
 * are the real cell p[1] = 4: `4 > 4` = 0, `4 < 9` = 1) and k = 6 >= m = 3 (the
 * guard is false; the read is of the zero cell: `0 > 4` = 0, `0 < 9` = 1). Every
 * bound derives from argc so clang -O1 cannot fold it (bd 46oo). The harness runs
 * with argc = 1.
 *
 * ⚠ The merge is `_Bool` on purpose: an `int` accumulator merges through the 4.4
 * DATA select. That select declined a hybrid classical∧quantum condition — the
 * second wall in front of the bead's own program (railbank_guarded_vla_matrix.c
 * CASE 6) — until bd xdu2.13 lowered the classical leaf as a `_hl` literal; the
 * in-loop program now declines at a third, pre-existing loop-layer wall (see
 * that matrix's CASE 6 note).
 */
#include "CQ.h"

__attribute__((noinline)) static int slice(int m, unsigned k) {
    if (m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    _Bool b = 0, c = 0;
    if (q && k < (unsigned)m) { b = p[k] > 4; c = p[k] < 9; }
    return cq_measure(q) + cq_measure(b) + cq_measure(c);
}

int main(int argc, char **argv) {
    (void)argv;
    return slice(argc + 2, (unsigned)argc) + slice(argc + 2, (unsigned)argc + 5);
}
