; control_swap_reject_select_fp_angle_fanout.ll — DECLINE (fp-data-select-PRD §5
; matrix 1): an fp-DATA-shaped select whose result ALSO reaches a rotation arg-1
; through a value-preserving CARRIER (`fpext`). Gate 3 (`selReachesRotationArg1`)
; runs BEFORE the gate-4 fp-data accept, so the un-staging cannot leak an angle
; along any carrier route: the FAN-OUT rule declines the WHOLE select (the
; result is measured as data AND feeds the angle — splitting double-realizes the
; value, a silent miscompile). This is the fp-accept-era restatement of
; control_swap_reject_select_angle_cast.ll (whose operands are classical
; constants); here the operands are tainted fp DATA — the exact shape gate 4
; now accepts — so ONLY the gate-3 fence stands between this and a miscompile.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define float @example(float %u0, i32 %u1, float %x) {
entry:
  %q   = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p   = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %c   = fcmp ogt float %q, 5.000000e+00
  %sel = select i1 %c, float %q, float %x          ; fp DATA shape (gate 4 would accept)
  %w   = fpext float %sel to double                ; value-preserving carrier
  call void @cq_phi(double %w)  ; arg-1 ANGLE reach -> decline WHOLE select
  %m   = call float @cq_measure_f32(float %sel)    ; fan-out: ALSO a data sink
  %m2  = call i32 @cq_measure_si32(i32 %p)
  ret float %m
}
