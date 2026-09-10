; control_phase_nest_reject_rail_round2_inner_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5, Rule-13 round-3 probe `r07`): the ROUND-2 TAINT WINDOW
; (F-B1R2-1) reached through the 4.3 nest's INNER level. The inner rail `%b` is a
; theta on `%x = trunc %y` where `%y` is a 6.5 classical-call `%out` — classical
; to the round-1 ladder, tainted at final taint — and `%b3` is its sibling on the
; same rail. The inner rail's ONLY read is the conjunction toffoli that
; `emitPhaseKickbackNestRegion` emits through `emitCondNode`; on f8d29e8 (the
; round-2 fix's own first spelling recorded the OUTER root only) this module
; ACCEPTED with `ry(h,.5); ry(h,.9); toffoli(…)`. `reverifyRailCondReads` now
; re-asks the wire question at that toffoli under FINAL taint.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %co = icmp sgt i32 %q, 7
  br i1 %co, label %mid, label %join
mid:
  br i1 %b, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %zz, %n
  %u = add i32 %t, %keep
  ret i32 %u
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
