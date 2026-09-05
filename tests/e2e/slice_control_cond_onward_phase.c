/* 3qlq Inc 1: migrated to register-free cq_phi -- the ONWARD phase after the data-mux loses its register.
   FLAG: this call is UNCONTROLLED (it sits after the switch merge, not inside an arm),
   so under D2 it is a GLOBAL phase and is DELETED. The slice's stated purpose -- the
   dugh re-propagation that re-taints the onward cq_phi so it lowers as a gate on %out
   -- has NO CUSTOMER left in this program. Purpose does NOT survive.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
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
int slice(void) {
    int q = 3, r = 3;              /* r preset to v_d (the default value)         */
    q = cq_theta(q, 0.5);          /* taint q -> scrutinee handle                */
    switch (q) {                   /* tainted switch -> preload + XOR-delta mux   */
        case 0:  r = 7;  break;    /* delta 7^3=4                                 */
        case 5:  r = 9;  break;    /* delta 9^3=10  (non-contiguous: defeats fold)*/
        case 17: r = 11; break;    /* delta 11^3=8                                */
    }
    cq_phi(0.25);           /* ONWARD phase on the muxed answer (Rz on out)*/
    return cq_measure(r);          /* reads the phased muxed answer               */
}
int main(void) { (void) slice(); return 0; }
