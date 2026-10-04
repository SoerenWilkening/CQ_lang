/* slice_control_phase_perbit_loop_merge_preadd.c — bd test_C_libtooling-3qlq
   Increment 1, the FOURTH C-1 round (bd 7yd0 / OQ-C2-1 / review_inc2_r2 finding
   **F-I2-1**).

   `slice_control_phase_perbit_loop_mixed_preadd.c`'s shape with ONE thing
   changed: the loop-INVARIANT register the per-bit condition reads is not a
   `cq_theta` ROOT MINT, it is a **Phase-4 CONTROL-OWNED MERGE OUT-RAIL** — here
   the 4.4 tainted-condition select merge's `%out`.

       int q = 3; cq_theta(&q, 0.5);
       int p = 7; cq_theta(&p, 0.25);
       int r = 9; cq_theta(&r, 0.3);
       int m = (q > 5) ? p : r;             // 4.4 SELECT merge  ->  %out rail
       m = m + 7;                           // PREHEADER dtzb op ON that rail
       for (int i = 0; i < 4; i++)
           if ((m >> i) & 1) cq_phi(0.7);   // D4's per-bit kickback, ROLLED
       return cq_measure(m);

   WHAT IT MEASURES, AND WHY NOTHING ELSE DID. The tree had both axes and never
   their product: six `control_phase_kickback_mixed_preheader_*.ll` fixtures pin
   the preheader in-place op (every one on a theta root), one
   `control_phase_kickback_inloop_merge_rail.ll` pins the merge-out-rail root
   (with no preheader op), and the loop-twin matrix's sub-grid F3 had two cells,
   both theta roots. MEASURED on `main` a3c1513: `cq_template_and_i32_hl` **4 /
   `_unc` 0** (44-line trace) against this pair's twin at **4/4** (52 lines), at
   `opt` exit 0, verify-clean and STRICT stage 2b `0 violation(s)`. At K=32 it is
   32 mints / 0 — the leak is O(K).

   THE CAUSE was `commitOutOfLoopInPlaceOps`' stability conjunct
   `P->hasOneUse()`. A merge out-rail structurally CANNOT have one use: the
   Phase-4 emitters WRITE it (two `cqrt_copy_i32_controlled` here) before
   anything reads it. `hasOneUse` cannot tell a prior WRITER from a later READER;
   `classifyInPlaceReassignment`'s own G6/G7 pair can, and does. The conjunct is
   retired and the safety is the (1b) `PreLoopCommittedInPlaceOps` tripwire,
   which re-asks the same fence at `lowerOps` and declines LOUDLY on a changed
   answer. See that function's header.

   Four live which-path records of the merged register's low bits survive the
   loop, so rolled and unrolled were DIFFERENT UNITARIES (Rule 8) — and stage 2b
   is structurally blind to it (a leaked TEMPLATE-minted rail has no
   `cqrt_alloc` to count; it reported `0 violation(s)` on the broken circuit).

   THE WITNESS IS THE `cmp` GATE `e2e-phase-perbit-loop-merge-preadd-twin-identical`,
   not this file alone: a golden regenerated on a leaking binary is
   self-consistent. `..._merge_preadd_unrolled.c` is the twin. The lit-layer
   stand-in is `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`,
   and the loop-twin matrix's sub-grid F4 carries the same axis at K=2. */
int slice(void) {
  int q = 3, p = 7, r = 9;
  cq_theta(&q, 0.5);
  cq_theta(&p, 0.25);
  cq_theta(&r, 0.3);
  int m = (q > 5) ? p : r;
  m = m + 7;
  for (int i = 0; i < 4; i++)
    if ((m >> i) & 1) cq_phi(0.7);
  return cq_measure(m);
}

int main(void) { (void)slice(); return 0; }
