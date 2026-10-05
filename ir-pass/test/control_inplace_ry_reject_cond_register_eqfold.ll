; control_inplace_ry_reject_cond_register_eqfold.ll — DECLINE, an OVER-DECLINE
; recorded as a gap (R1): the EQUALITY spelling of bd test_C_libtooling-dm7f.4.
;
;     int q = u; cq_theta(&q, .5);
;     if (q == 5) cq_theta(&q, .3);
;     return cq_measure(q);
;
; The source is the same class `control_inplace_ry_cond_register_flag_kept.ll`
; lowers (an Ry on the condition's own register inside its branch), but `-O1`
; substitutes the edge fact q == 5 into the arm, so the pass receives
; `cq_theta_si32(i32 5, …)`: a controlled STATE PREP with seed 5 whose merge
; muxes the prepared rail against the live register q. F1 refuses that as
; `state prep merged with a quantum register`, before R4 is ever asked (R4 is
; skipped for a state prep). The IR below is the `-O1` output, verbatim.
;
; THE PHYSICS IS NOT THE OBSTACLE. On the f=1 branch q holds |5>, which is the
; seed, so un-folding the arm (arg-0 := the compare's register when the arm
; edge pins it to the seed) gives exactly the dm7f.4 stream:
;     f = icmp_eq_hl(q, 5); cry(f, q, .3); f kept, never freed.
; That un-fold (a polarity proof over the eq/ne edge, F1/F2 bypassed only for a
; register the compare itself pins) is not built.
;
; RETIREMENT TRIGGER: when it lands, this module ACCEPTS with that stream and
; one M-A warning. Re-derive the CHECK lines from the binary then and rename the
; file without `_reject_`; do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: state prep merged with a quantum register under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 5, double 3.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
