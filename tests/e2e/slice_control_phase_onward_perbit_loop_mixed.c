/* slice_control_phase_onward_perbit_loop_mixed.c — bd test_C_libtooling-3qlq
   Increment 1, the SECOND C-1 review round, finding **F-C1-2(2a)** (CONFIRMED
   MISCOMPILE, twin witness).

   THE MIXED **ONWARD** LOOP: D4's per-bit idiom on a loop-INVARIANT register
   that is a Phase-6.5 classical-call-arm `%out` rail — a region no stage sees
   until ROUND 2 — inside a loop that ALSO CARRIES a second tainted register.

       int q = cq_theta(u, 0.5);
       int r = cq_theta(u, 0.3);            // CARRIED: rotated once per trip
       int y = 5; if (q > 5) y = ext_f(7);  // 6.5 arm  ->  %out (INVARIANT)
       for (int i = 0; i < 3; i++) {
           if ((y >> i) & 1) cq_phi(0.25);  // D4's per-bit kickback on %out
           r = cq_theta(r, 0.1);
       }
       y = cq_theta(y, 0.9);                // the DIFFUSION
       return cq_measure(r) + cq_measure(y);

   WHAT IT MEASURES, AND WHY THE ROUND-1 ONWARD FIX DID NOT COVER IT. Round 2's
   F-R1-1 fix re-runs `collapseFlattenedLoopRails` after the onward fixpoint, and
   the C-1 fix taught it to admit an invariant register BESIDE a carried one — but
   only when the CARRIED rail's collapse happened in that SAME call. Here it did
   not: at round 1 `%out` does not exist, so the loop's in-body control is
   CLASSICAL and ROUND-1 `lowerLoops`/`tryCaseA` claims and collapses the carried
   rail itself. By the round-2 pass there is no tainted header phi left, the local
   carried set is EMPTY, and clause (iii) refused on the carried root's in-body
   `cq_theta(r,.1)` — taking the INVARIANT register's discharge down with it.

   MEASURED on 542d588 AND on the round-1 C-1 fix: `cq_template_and_i32_hl` 3 /
   `_unc` **0** against this pair's twin at 3/3; the `diff` of the two traces is
   EXACTLY the three inserted `_unc` + `cqrt_free` pairs. `opt` exit 0,
   verify-clean, STRICT stage 2b `0 violation(s)` on both — the checker cannot see
   a leaked TEMPLATE-minted rail. The three live records of `%out`'s low bits then
   survive into `cqrt_ry_i32(%out, 0.9)`: rolled and unrolled were DIFFERENT
   UNITARIES (Rule 8).

   THE FIX is `taint.ClaimedRailRoots` — the "a Case-A collapse already claimed
   this rail" fact taken from the TREE (written at BOTH collapse sites) rather
   than from the caller's local set — skipped INTO the Root set so
   `markIfRailLocal`'s `onRail` can see it.

   THE WITNESS IS THE `cmp` GATE `e2e-phase-onward-perbit-loop-mixed-twin-identical`.
   The lit stand-in is `control_phase_kickback_mixed_onward_inloop.ll`; the
   discriminating leak control is `..._mixed_onward_deadgate_leak_control.ll` (the
   same program with the body's gate result DEAD, so no collapse ever claimed the
   rail — it still leaks, and must). */
int ext_f(int a);

int slice(int u) {
  int q = cq_theta(u, 0.5);
  int r = cq_theta(u, 0.3);
  int y = 5;
  if (q > 5) y = ext_f(7);
  for (int i = 0; i < 3; i++) {
    if ((y >> i) & 1) cq_phi(0.25);
    r = cq_theta(r, 0.1);
  }
  y = cq_theta(y, 0.9);
  return cq_measure(r) + cq_measure(y);
}

int main(void) { (void)slice(5); return 0; }
