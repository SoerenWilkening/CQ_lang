; lowering_reject_uncompute_measured_parent_per_component_read_after_measure.ll
; — DECLINE (bd test_C_libtooling-01po.12; decline twin of
; lowering_uncompute_measured_parent_per_component.ll). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int t = q ^ 9;
;                       cq_theta(&t, .5); int m = cq_measure(q);
;                       int u = q ^ 5; cq_theta(&u, .3); return m; }
;
; THE NEIGHBOUR THE PER-COMPONENT RETRY MUST NOT TAKE. The reduced DAG has two
; components, {t} and {u}, sharing only the borrowed measured `q`. {t} proves out
; at its own reversal point (it is the bd ptue accept). {u} reads q AFTER q's
; measurement — bd yiid, a RULED capability (owner 2026-09-14; E3 (b) BROAD
; 2026-09-15) that is not built, so its reversal would replay a post-collapse read
; (`xor_hl_unc(u, q, 5)` after `measure(q)`). `measuredParentsReadBeforeCollapse`
; is asked PER COMPONENT, refuses {u}, and one refused component keeps the whole
; module's decline verbatim (nothing is emitted for {t} either).
;
; A loud over-decline pending E3, not a physics wall (R1). RETIREMENT TRIGGER
; (L7): when E3 lands, re-derive this file with
; lowering_reject_uncompute_measured_parent_read_after_measure.ll.
;
; bd dm7f.83 (ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16): FLIPPED TO
; LOUD. A classical-immediate in-place site here is refused by the M-C fence
; (`inPlaceFenceHolds`, G7: an earlier reader of the register has an obligation
; not yet settled, so in place could corrupt that reader's adjoint (a late
; discharge of the dead parent after its readers' adjoints is the build)) while
; its handle is a DEAD USER REGISTER (register-level: no later read, rotation
; or measure of its rail under any SSA name, `registerLiveAfter`, bd dm7f.83.3)
; beside a KEPT result, so out of place would leave the old rail beside the
; result, the r2j3.33 hazard class. MEASURED (laneL/dm7f83_flips.md): in THIS
; fixture that fallback was observably correct (the record is only measured, or
; every later Ry on it cancels, or its which-path information already sits in
; another kept rail), so this decline is the ruling's, an over-decline until
; the refusal is lowered. The in-place round now fails
; loudly (InPlaceQQImm.cpp), as owner Q1 requires. The fixture's original
; expectation is kept dormant: its RUN lines are spelled MC-CMD and no RUN line
; reads its CHECK prefixes. RETIREMENT: restore them when the refused shape
; converts (G7's lowering, named above).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DM7F83
; DM7F83: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
;
; MC-CMD: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_theta_si32(i32 %3, double 5.000000e-01)
  %5 = tail call i32 @cq_measure_si32(i32 %2)
  %6 = xor i32 %2, 5                                            ; reads q AFTER the collapse
  %7 = tail call i32 @cq_theta_si32(i32 %6, double 3.000000e-01)
  ret i32 %5
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
