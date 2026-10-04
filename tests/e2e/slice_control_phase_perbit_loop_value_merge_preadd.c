/* slice_control_phase_perbit_loop_value_merge_preadd.c — bd
   test_C_libtooling-3qlq, the FOURTH C-1 round (bd 7yd0) REBASED onto the
   landed **Increment 2** (`main` 258d974, value arms by the CONTROLLED-COPY
   MERGE).

   `slice_control_phase_perbit_loop_merge_preadd.c`'s shape with ONE thing
   changed: the loop-INVARIANT register the per-bit condition reads is not the
   4.4 SELECT merge's `%out` — it is the **Inc-2 VALUE-ARM merge's** `%out`,
   produced by a tainted-condition if-diamond whose arm rewrites `p` through a
   six-op pure chain.

       int q = cq_theta(3, 0.5);
       int p = cq_theta(7, 0.25);
       if (q > 3) { p = p+3; p = p*5; p = p^9;
                    p = p+1; p = p*7; p = p^2; }  // Inc-2 VALUE ARM -> %out
       p = p + 7;                                 // PREHEADER dtzb op ON it
       for (int i = 0; i < 4; i++)
           if ((p >> i) & 1) cq_phi(0.7);         // D4's per-bit kickback, ROLLED
       return cq_measure(p);

   WHY IT EXISTS. Round 4 (bd `7yd0`) fixed this leak for the three producers of
   a merge out-rail that existed on `main` a3c1513 (the 4.4 select merge, the
   Phase-4 value-arm ROUTE, and a preceding region's own compare). Increment 2
   then landed a FOURTH producer, and the round could only ARGUE that its fix
   serves it — its own record says the row "CANNOT be measured until the
   orchestrator rebases this branch onto the landed Inc 2". THIS PAIR IS THAT
   MEASUREMENT. The Inc-2 merge writes `%out` with TWO `cqrt_copy_i32_controlled`
   before anything reads it, so `P->hasOneUse()` — the conjunct round 4 retired —
   refused it exactly as it refused the other three.

   MEASURED, this program, `inc1-records/c1-round4/q4b_preadd_rolled.c`:
     * on `main` **258d974**: rolled `cq_template_and_i32_hl` **4 / `_unc` 0**,
       52-line trace, against this twin at **4/4**, 60 lines — `cmp` DIVERGE 8,
       at `opt` exit 0, verify-clean, and STRICT stage 2b `0 violation(s), 0
       unproven` (2b is structurally blind: a leaked TEMPLATE-minted rail has no
       `cqrt_alloc` to count);
     * here: **4/4 = 4/4, 60 = 60, byte-identical** — and the rolled trace is
       byte-identical to `main`'s OWN unrolled twin, so the comparison is against
       the landed compiler's stream and not against itself.

   Four live which-path records of the merged register's low bits survive the
   loop on `main`, so rolled and unrolled are DIFFERENT UNITARIES there (Rule 8).

   THE WITNESS IS THE `cmp` GATE
   `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`, not this file
   alone: a golden regenerated on a leaking binary is self-consistent.
   `..._value_merge_preadd_unrolled.c` is the twin; the lit-layer stand-in is
   `control_phase_kickback_mixed_value_merge_preadd_inloop.ll`.

   NOTE the chain FINAL rail is left ALLOCATED and entangled on purpose (PRD §0
   E1), and `clang -O1` reassociates `(p+3)*5` into `p*5 + 15`, so the hoisted
   chain HEAD is a `cq_template_mul_i32_hl` — OUT of place, on a fresh rail,
   because `p` is read by the ¬flag arm of the merge. That is the F-C1D-2
   property: the round-4 commit cannot reach an Inc-2 chain head. */
int slice(void) {
  int q = 3, p = 7;
  cq_theta(&q, 0.5);
  cq_theta(&p, 0.25);
  if (q > 3) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
  p = p + 7;
  for (int i = 0; i < 4; i++)
    if ((p >> i) & 1) cq_phi(0.7);
  return cq_measure(p);
}

int main(void) { (void)slice(); return 0; }
