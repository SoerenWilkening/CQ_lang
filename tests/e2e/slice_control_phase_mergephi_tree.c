/* slice_control_phase_mergephi_tree.c — bd `4aiu` (Track P). THE INTERIOR-LEAF
   customer, e2e: a prep merge phi as a LEAF of a compound condition rather than
   as the whole condition (`if (b1 && q > 3) cq_phi(0.3);`).

   `clang -O1` hands that over as `select i1 %phi, i1 %cmp, i1 false` — the
   canonical LLVM-19 spelling of C's short-circuit `&&`, which the branch-phase
   grammar has admitted as a node since bd 3qlq.4. Only the phi LEAF was
   off-grammar, and only because Track M scoped its admission to the tree's ROOT.

   IT DECLINED ON THE FROZEN ORACLE (`59ac5b7`) with `control flow` — correctly
   partitioned, since a compound condition is a TREE and not a bare `i1`.

   READ THE GOLDEN:
      1-2   `q`'s rail + its Ry.
      3-4   `b0`'s rail + its Ry.
      5-6   `b1`'s rail, PREPPED and rotated under `b0` (this arm is the TRUE
            successor, so one controlled Ry and no cancelling clone).
      7     the compare leaf's flag, minted from `q`.
      8-9   the AND node's |0> ancilla and the `cqrt_toffoli` that computes
            `b1 & (q>3)` onto it — the prepped register read as a READ-ONLY
            CONTROL, which is the whole content of the widening.
     10     `cqrt_rz_i1` on that ancilla: the phase lands on exactly the marked
            branch.
     11-14  the LIFO teardown — the same toffoli (self-inverse) returns the
            ancilla to |0> on EVERY branch, then its proven-|0> free, then the
            compare `_unc` and the flag's free (Rule 6).
     15-17  the three measurements.

   INVARIANTS: NO `cqrt_x` anywhere; the two user registers `h1` (`b0`) and `h2`
   (`b1`) are never bracketed and never freed; STRICT stage 2b reports
   `4 rail mint(s) of which 3 left allocated, 2 cqrt_free site(s): 2 verified,
   0 violation(s), 0 unproven`.

   ⚠ CROSS-CHECK: lines 7-14 are what the FROZEN ORACLE prints for the hand-IR
   twin `trackP/probes/p18.ll` (the same module after M-beta, where the phi is
   already a `cq_theta_i1` call and therefore an ordinary interior RAIL leaf).
   Same gates, same order. The widening adds an ACCEPT, not a STREAM. */
int slice(void) {
    int q = 0; cq_theta(&q, 0.7);
    _Bool b0 = (_Bool)0; cq_theta(&b0, 0.5);
    _Bool b1 = 0;
    if (b0) { cq_theta(&b1, 0.5); }
    if (b1 && q > 3) cq_phi(0.3);
    return (int) cq_measure(b0) + (int) cq_measure(b1) + cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
