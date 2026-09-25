/* slice_loop_condtree_select_hoisted_unrolled.c — the HAND-UNROLLED twin of
   `slice_loop_condtree_select_hoisted.c` (bd `test_C_libtooling-xdu2.16`).

   Three written-out copies of the loop body with `i` spelled 0, 1, 2. `clang -O1`
   CSEs the three identical condition trees into ONE `and i1` in the entry block
   that all three selects read; the first two emitters leave it (it still has
   users) and the third erases it — the flat analogue of the rolled form's erase.
   This half lowers on the pre-change ORACLE `438c77bf45c02e3e` as well: it has
   no loop, so no loop-layer grant.

   ⚠ WHY A PER-TRIP MEASURE AND NOT AN ACCUMULATOR. `a += 3` three times folds
   across the copies (`-O1` turns the flat form into ONE select of `9`), and a
   loop-carried classical seed makes trip 1's select take CLASSICAL arms on the
   flat side while the rolled side promotes the seed to a rail (bd `zujr`'s
   first-trip spelling difference, recorded in `condtree_classical_leaf_matrix.c`
   CASE 10). The measured `t` has neither problem, so the two traces can be — and
   are — byte-identical, handle numbering included.

   THE GATE: `e2e-loop-condtree-select-hoisted-twin-identical` compares the two
   committed goldens byte for byte. */
int slice(void) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? 0 : 55; s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 1 : 55; s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 2 : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { (void) slice(); return 0; }
