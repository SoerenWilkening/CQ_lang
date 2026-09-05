; control_swap_reject_nested_select.ll — DECLINE: an inner select under an outer
; tainted branch.
;
; `if (q>5) { q = rz(q,b); q = (q<9) ? (q+1) : (q+2); }` — clang -O1 if-converts
; the speculatable inner `?:` to `q + select(q<9, 1, 2)`, collapsing the would-be
; nest to a FLAT one-content-arm diamond whose Mid holds a tainted value chain
; bottoming at an in-arm select. The outer diamond reaches ArmClassify, whose
; value-chain walk bottoms IN the arm (not at the routed register) → `control
; flow` — fired on the OUTER branch before the inner select scan, so the
; 4.4-unbuilt `select` string never surfaces here. Over-declining is safe (Prime
; Directive); pinned to the string that actually fires on real -O1.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  %sel = select i1 %c2, i32 1, i32 2
  %add = add nsw i32 %sel, %q
  br label %merge
merge:
  %qm = phi i32 [ %add, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}lowering: control flow under quantum control
