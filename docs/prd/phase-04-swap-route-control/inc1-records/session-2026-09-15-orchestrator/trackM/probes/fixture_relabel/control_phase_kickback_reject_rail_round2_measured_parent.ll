; control_phase_kickback_reject_rail_round2_measured_parent.ll — DECLINE (bd
; test_C_libtooling-r9e5, Rule-13 round-3 probe `r25`): RUNG (ii) of the rail
; ladder through the ROUND-2 TAINT WINDOW at the KICKBACK (the round-2 fix shipped
; the select's form, `..._select_rail_round2_measured_parent.ll`). `%x = trunc %y`
; is classical at round 1 (`%y` a 6.5 `%out`) and tainted at final taint, so the
; `cq_measure(%x)` before `%b = cq_theta(%x, .5)` is a measurement of the rail the
; kickback then fires on — invisible to `railWireNamesBackward` at round 1 (the
; closure stopped at a "source" theta) and visible at the re-ask. ACCEPTED on
; f8d29e8.
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
  %mx = call i1 @cq_measure_i1(i1 %x)
  %b = call i1 @cq_theta_i1(i1 %mx, double 5.000000e-01)
  br i1 %b, label %then, label %join
then:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %zx = zext i1 %mx to i32
  %t = add i32 %zx, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
