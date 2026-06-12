; control_swap_reject_nested_botharm_asym.ll — DECLINE: ASYMMETRIC both-arm nest
; (a genuine 4-incoming merge).
;
; `if (q>5) { if (q<20) rz(q,a); } else { if (q>2) rz(q,b); }` — distinct
; per-arm gates, so nothing hoists and the merge has FOUR incomings. The OUTER
; branch carries tainted inner gates on BOTH successors → NOT a one-content-arm
; diamond → criterion 1 declines `nested control flow` before the 4-incoming
; merge is ever examined (§12.7 depth cap is incidental here).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %then, label %else
then:
  %ct = icmp slt i32 %q, 20
  br i1 %ct, label %tarm, label %merge
tarm:
  %tg = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
else:
  %ce = icmp sgt i32 %q, 2
  br i1 %ce, label %earm, label %merge
earm:
  %eg = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q, %then ], [ %tg, %tarm ], [ %q, %else ], [ %eg, %earm ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
