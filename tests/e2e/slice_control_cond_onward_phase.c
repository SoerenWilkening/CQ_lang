/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, finding F-B2-3 / prep-b2, orchestrator remedy).
   The golden below is a NEW PROGRAM's trace, not an audit substitution of the old
   one, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md §12.

     OLD: cq_phi(0.25);                          (an UNCONTROLLED onward Rz on %out)
     NEW: int t = r + argc;  if (t == 10) cq_phi(0.25);   (an ONWARD KICKBACK)

   WHY. The onward call sits AFTER the switch merge, so it is uncontrolled, and
   under owner decision D2 an uncontrolled `cq_phi` is a GLOBAL PHASE and is
   DELETED. MEASURED before this rewrite: the golden lost its only `cqrt_rz` line
   and this slice — whose whole subject is the `dugh` SECOND propagation round
   (`repropagateControlMerges` re-seeding taint from the emitted `%out` so an
   onward op over the data-mux result lowers and LINKS) — had no onward op left to
   re-taint. The 4.5 switch data-mux half kept working, which is exactly what made
   the loss invisible.

   WHAT THE NEW ONWARD OP IS, AND WHY IT IS BETTER THAN THE OLD ONE. `t = r + argc`
   is a real onward ARITHMETIC op on the merged rail (it emits
   `cq_template_add_i32_hl` on `%out` and its `_unc` twin), and the compare on `t`
   mints a flag that carries the branch phase by kickback. So the second
   propagation round is now proved by TWO consumers of `%out` — an arithmetic op
   and a control region — where it used to be proved by one in-place gate.

   ⚠ `argc` IS LOAD-BEARING, NOT STYLE, AND IT IS MEASURED. Written as the obvious
   `if (r == 9) cq_phi(0.25);`, `clang -O1` HOISTS the comparison INTO the switch:
   the merge block gets a SECOND phi, `%6 = phi i1 [false,%entry],[false],[true],[false]`,
   beside the i32 data mux, and the module declines
   `cq controlled lowering: control flow under quantum control` (the C1 multi-phi
   row). Adding a run-time classical operand the compiler cannot evaluate per arm
   defeats that hoist and leaves the merge a pure data mux, which is the shape this
   slice is about. `argc` is 1 on every real invocation, so `t == 10` means `r == 9`
   — the `case 5` arm — which is the value the original comment named. Note the
   trace does not depend on that: the kickback is quantum control, so the flag mint,
   `cqrt_rz_i1`, the strip and the free are emitted unconditionally.

   Same `argc` trick, same reason, as `slice_classical_if_gate.c`. */
/* slice_control_cond_onward_phase.c — dugh (Phase 4×6) e2e smoke: an untainted
   control-merge result feeding an ONWARD-QUANTUM PHASE (Rz), driven through the full
   clang -O1 → opt cq-lowering → link → run pipeline. The only test layer that LINKS,
   so the ONLY proof that the re-tainted onward `cqrt_rz_i32` over the data-mux `%out`
   resolves + signature-matches against libcq_runtime (Rule 2, Rule 16) — the
   second-propagation round wired for real.

   SOURCE INTENT (the (A2) onward-QUANTUM subset dugh converts from decline):
       q : tainted quantum SCRUTINEE handle
       int r = 3;                                  // the default value v_d
       switch (q) { case 0: r=7; case 5: r=9; case 17: r=11; }   // all-const data-mux
       cq_phi(0.25);                        // ONWARD phase on the muxed answer
       measure(r)

   The switch merge is all-ConstantInt => data-untainted, so the FIRST propagation
   classified `cq_phi(r, …)` classical. PRE-dugh the `proveSwitchDataMux` merge-out
   gate declined it (the onward `cq_phi` read the i32 %out handle as a value). dugh
   RE-SEEDS a second propagation from the emitted `%out` (`repropagateControlMerges`,
   right after `lowerControlRegions`), so the onward `cq_phi` is re-tainted and lowers
   IN PLACE to `cqrt_rz_i32(out, 0.25)` (a phase arm — the answer stays on out, zero
   controlled gates); the measure reads out. The opaque `cq_phi` is what keeps this
   test HONEST: unlike a stock `r + const` (which clang -O1 folds into the switch
   incomings, erasing the onward op), clang cannot fold/sink an opaque call across the
   merge, so a REAL onward-quantum op survives to opt.

   Same two -O1-survival tricks as slice_control_switch_datamux.c: NON-CONTIGUOUS
   case values (0, 5, 17) defeat the select/lookup-table fold, and PRE-INIT r = v_d
   with no explicit `default:` body makes the entry straight-through carry v_d (the
   §4C preload). out (a ControlOwnedRail), q, and every XOR-delta scratch are NEVER
   freed (benign leak, Rule 6); EXACTLY THREE frees (the N=3 eq-flags). The onward Rz
   is applied to out IN PLACE and out is MEASURED. The golden pins the trace from REAL
   linked output (templates BEFORE runtime — load-bearing link order). */
int slice(int argc) {
    int q = 3, r = 3;              /* r preset to v_d (the default value)         */
    cq_theta(&q, 0.5);             /* taint q -> scrutinee handle                */
    switch (q) {                   /* tainted switch -> preload + XOR-delta mux   */
        case 0:  r = 7;  break;    /* delta 7^3=4                                 */
        case 5:  r = 9;  break;    /* delta 9^3=10  (non-contiguous: defeats fold)*/
        case 17: r = 11; break;    /* delta 11^3=8                                */
    }
    int t = r + argc;              /* ONWARD arithmetic on the muxed answer      */
    if (t == 10) cq_phi(0.25);     /* ONWARD BRANCH phase by kickback (argc==1)  */
    return cq_measure(r);          /* reads the phased muxed answer               */
}
int main(int argc, char **argv) { (void) argv; (void) slice(argc); return 0; }
