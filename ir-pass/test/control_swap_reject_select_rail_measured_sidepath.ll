; control_swap_reject_select_rail_measured_sidepath.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): the measurement of the register sits on a
; CLASSICALLY-GUARDED SIDE PATH — it neither shares the select's block nor
; dominates it, yet executes before the select on that path.
;
; This is the 3qlq.4 round-1 finding F-1b-2 shape, inherited: the rung asks
; REACHABILITY (`isPotentiallyReachable(measure, Sel)`), not dominance, so "can
; the select execute after this measurement on SOME path?" is the question. It
; is a documented OVER-DECLINE on the paths where the guard is not taken
; (OQ-1b-R2-4) and is kept: over-declining is safe, a post-measure gate is not.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %mm, label %pred
mm:
  %m0 = call i1 @cq_measure_i1(i1 %b)
  br label %pred
pred:
  %p = phi i1 [ %m0, %mm ], [ false, %entry ]
  %a = select i1 %b, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %z = zext i1 %p to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
