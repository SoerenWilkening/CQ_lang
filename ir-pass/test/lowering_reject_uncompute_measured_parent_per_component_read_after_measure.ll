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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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
