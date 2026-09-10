; control_swap_reject_value_rail_cond.ll — DECLINE (bd 3qlq.4, follow-on 1b-B):
; a VALUE arm (`if (b) a = a + 3` on a quantum `a`) under a bare-rail condition.
; Inc 2's emitter hoists the chain and hands a `select` to the 4.4 merge, whose
; classifier is where the rail is refused — the same string as the data select,
; because it IS the same missing lowering (a copy merge controlled on the
; register).

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  %a2 = add i32 %a, 3
  br label %merge
merge:
  %aa = phi i32 [ %a2, %arm ], [ %a, %entry ]
  %n = call i32 @cq_measure_si32(i32 %aa)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %s = add i32 %n, %z
  ret i32 %s
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
