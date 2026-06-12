; control_swap_reject_nested_depth3.ll — DECLINE: depth-3 nest (beyond the cap).
;
; `if(q>5){rz; if(q<20){rz; if(q>8){rz;}}}` (real clang -O1) — a genuine
; 4-incoming merge whose innermost arm-feeding block (%mid2) itself ends in a
; tainted br. The inner content arm is therefore not single-pred + unconditional
; into the outer merge → criterion 2 (depth-2 cap) declines `nested control
; flow` BEFORE descending into a sub-region the outer flatten would erase.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  %c2 = icmp slt i32 %g1, 20
  br i1 %c2, label %mid2, label %merge
mid2:
  %g2 = call i32 @cq_phi_si32(i32 %g1, double %b)
  %c3 = icmp sgt i32 %g2, 8
  br i1 %c3, label %arm, label %merge
arm:
  %g3 = call i32 @cq_phi_si32(i32 %g2, double %c)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g1, %mid ], [ %g2, %mid2 ], [ %g3, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
