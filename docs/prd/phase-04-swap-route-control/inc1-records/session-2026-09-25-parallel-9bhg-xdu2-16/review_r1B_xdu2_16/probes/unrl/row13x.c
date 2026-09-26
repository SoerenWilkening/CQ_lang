/* slice_loop_condtree_select_hoisted_row13.c — bd `test_C_libtooling-xdu2.16`:
   bd xdu2.8's OWN PROGRAM end to end — `railbank_dynamic_matrix.c` row 13
   (CASE_SPEC_GUARDED_BOUND), verbatim.

   Its walls, in the order they fell: E4-gep (bd xdu2.8's arm-guarded classical
   VLA read, `load(select(freeze idx <u freeze extent), &p[idx], zero cell))`) →
   the 4.4 select's untainted-leaf gate on the hybrid `and (m == n), (q != 0)` (bd
   xdu2.13: the classical leaf is the `cq_template_and_i1_hl` LITERAL) → the loop
   layer's round-2 grant re-ask, which refused the NULLED root left when the second
   select's emitter erased the LICM-hoisted `and` (bd xdu2.16: the grant is now
   re-derived from scratch under FINAL taint and must be TOTAL; it is — the body
   reads only the root mint `q`). On the pre-change ORACLE `438c77bf45c02e3e` this
   program exits 1 at that third wall; the matrices' row 13 / row 6 flip with it.

   Under the harness (`argc == 1`): n = 2 trips, m = 1 cell, so `m == n` is FALSE
   and the literal is 0 on both trips; the guarded read of p[1] (out of bounds —
   the arm-local guard is what made the SOURCE safe) reads the private zero cell
   instead. Per trip the golden shows the two chain ops on the CARRIED handles
   (`a` and `z`, promoted seeds — bd `zujr`/`h1ip`), then TWO independent
   `icmp_ne_hl` → `and_i1_hl(…, 0)` networks, one per select, each X-bracketed
   into a fresh `%out`, `_unc`'d with the SAME literal and freed. `h0` (the
   user's `q`) is only ever a template operand. Stage 2b STRICT.

   ⚠ NO TWIN, AND THAT IS A DECISION: a loop-carried accumulator's hand-unrolled
   spelling folds across copies and takes CLASSICAL arms on trip 1 (bd `zujr`'s
   first-trip spelling difference, `condtree_classical_leaf_matrix.c` CASE 10), so
   a byte twin is not constructible from C. The twin witness for this condition
   shape is `e2e-loop-condtree-select-hoisted-literal-twin-identical`; this slice is
   the LINK witness (every symbol resolves and signature-matches) for the bead's
   own program. */
#include <stdlib.h>
__attribute__((noinline)) static int slice(int n, int m) {
    if (n <= 0 || m <= 0) return 0;
    int p[m];
    for (int i = 0; i < m; ++i) p[i] = i + 3;
    int q = cq_theta(0, 0.25);
    int a = 0, z = 0;
    for (int i = 0; i < n; ++i)
        if (q && m == n) { a += p[i]; z -= p[i]; }
    return cq_measure(q) + cq_measure(a) + cq_measure(z);
}
int main(int argc, char **argv) { (void)argv; return slice(3, argc + 2); }
