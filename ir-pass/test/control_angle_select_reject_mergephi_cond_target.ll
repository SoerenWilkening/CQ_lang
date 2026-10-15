; control_angle_select_reject_mergephi_cond_target.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, adversarial): the Ry ANGLE SELECT rotates the
; register its MERGE-φ condition names.
;
;     if (a) cq_theta(&b, .5);  cq_theta(&b, b ? .7 : .3);
;
; The φ is the prep's register; rotating it under a copy of itself is the
; condition-register shape (dm7f.8) one name over, and S8's closure over
; `condProvenance(φ)` (φ, its arm theta) meets the base's wire. Loud.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation arm on a condition wire under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  br i1 %a, label %arm, label %merge

arm:
  %b1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  br label %merge

merge:
  %b = phi i1 [ %b1, %arm ], [ false, %entry ]
  %ang = select i1 %b, double 0x3FE6666666666666, double 3.000000e-01
  %b2 = call i1 @cq_theta_i1(i1 %b, double %ang) #0
  %ma = call i1 @cq_measure_i1(i1 %a)
  %mb = call i1 @cq_measure_i1(i1 %b2)
  %za = zext i1 %ma to i32
  %zb = zext i1 %mb to i32
  %s = add i32 %za, %zb
  ret i32 %s
}

attributes #0 = { nomerge nounwind }
