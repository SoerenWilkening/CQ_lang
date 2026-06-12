; control_swap_reject_nested_value_pure.ll — DECLINE: depth-2 nest, EVERY arm a
; value chain (the deferred pure-value-nest increment).
;
; `if (q>5) { q = q*7; q = q+11; if (q<12) { q = q*5; q = q+3; } }` (real clang
; -O1; the inner cond folds to q<12). Both the Mid arm and the inner arm bottom
; at value ops, so the tree is all-VALUE. The value-nest needs the method-B
; copy-out / reverse-play composition over the region tree (its own §8.2
; boundary + Rule-13 clearance) — declined `value-arm swap-route` until that
; increment (homogeneity criterion 6, before RAUW-collapse).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %t1 = mul nsw i32 %q, 7
  %g  = add nsw i32 %t1, 11
  %c2 = icmp slt i32 %q, 12
  br i1 %c2, label %arm, label %merge
arm:
  %t2 = mul nsw i32 %g, 5
  %h  = add nsw i32 %t2, 3
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}value-arm swap-route under quantum control
