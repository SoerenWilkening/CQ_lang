; control_swap_reject_nested_multireg.ll — DECLINE: depth-2 nest, cond on q,
; arms gate p (the MULTI-REGISTER false-accept, the pre-clearance blocker).
;
; `if (q>5) { p = rz(p,b); if (q<9) { p = rz(p,a); } }` (real clang -O1). Every
; merge incoming is p-lineage, so criterion 4 (RAUW-collapse) PASSES — yet the
; inner condition reads q, OUTSIDE the diagonal-alias closure of the value the
; parent routes onto rail1 (%pg, p-lineage). Minting the inner flag from rail1
; (which holds p) would compute p<9 where the source wrote q<9: a verify-clean
; SILENT miscompile. Criterion 5 (mint-from-rail, the load-bearing binding
; signal) declines it — proving criterion 4 is necessary-not-sufficient
; (IMPLEMENTATION-4.3 §0). Detection is by SSA identity before any mutation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
