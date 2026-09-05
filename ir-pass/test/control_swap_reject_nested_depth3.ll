; control_swap_reject_nested_depth3.ll — DECLINE: depth-3 nest (beyond the cap).
;
; `if(q>5){rz; if(q<20){rz; if(q>8){rz;}}}` (real clang -O1) — a genuine
; 4-incoming merge whose innermost arm-feeding block (%mid2) itself ends in a
; tainted br. The inner content arm is therefore not single-pred + unconditional
; into the outer merge → criterion 2 (depth-2 cap) declines `nested control
; flow` BEFORE descending into a sub-region the outer flatten would erase.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %a)
  %c2 = icmp slt i32 %q, 20
  br i1 %c2, label %mid2, label %merge
mid2:
  call void @cq_phi(double %b)
  %c3 = icmp sgt i32 %q, 8
  br i1 %c3, label %arm, label %merge
arm:
  call void @cq_phi(double %c)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
