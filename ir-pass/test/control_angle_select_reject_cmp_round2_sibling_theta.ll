; control_angle_select_reject_cmp_round2_sibling_theta.ll — DECLINE (Track A.1,
; bd test_C_libtooling-9pum): the ROUND-2 TAINT WINDOW at the Rz-stem ANGLE
; SELECT, with a COMPARE leaf. The compare twin of
; `control_angle_select_reject_phase_rail_round2_sibling_theta.ll`.
;
; MEASURED on `main` 0c7380c — exit 0, verify-clean, and the emitted stream is
;
;     cqrt_ry_i32(%out, 0.5)                       <- b
;     cqrt_ry_i32(%out, 0.9)                       <- b3, SAME rail
;     cq_template_icmp_sgt_i32_hl(%out, 0)         <- the flag, post-both
;     cqrt_rz_i1(flag, 0.3);  cqrt_rz_i1(flag, 0.9)
;
; i.e. the branch-phase pair rides a predicate the source never wrote. The angle
; select gets no classifier clause for this rung either; it is caught by
; `reverifyCmpCondReads` over `AngleSelectEmit`'s own `lowerCompareToFlag` call.

; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

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
  %keep = add i32 %y, 0
  br label %second

second:
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %cc = icmp sgt i32 %b, 0
  %ang = select i1 %cc, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %mm = call i32 @cq_measure_si32(i32 %b3)
  %t = add i32 %mm, %keep
  %cq.main.m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %cq.main.m
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
