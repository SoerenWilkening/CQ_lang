; control_swap_reject_nested_twophi.ll — DECLINE: depth-2 nest whose inner cond
; and inner arm touch DIFFERENT registers, so real clang -O1 emits TWO phis at
; the 3-incoming merge.
;
; `if (q>5) { q = rz(q,b); if (r<9) { q = rz(q,a); r = rz(r,a); } }` — the merge
; carries a q-phi AND an r-phi. Criterion 3 (exactly-one merge phi) declines
; `control flow`: the relaxed 3-incoming recognizer mirrors soleMergePhi's
; one-phi discipline (a two-register merge is not the §0 shape).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %qg = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %r, 9
  br i1 %c2, label %arm, label %merge
arm:
  %qh = call i32 @cq_phi_si32(i32 %qg, double %a)
  %rh = call i32 @cq_phi_si32(i32 %r, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %qh, %arm ], [ %qg, %mid ], [ %q, %entry ]
  %rm = phi i32 [ %rh, %arm ], [ %r, %mid ], [ %r, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %qm)
  %m2 = call i32 @cq_measure_si32(i32 %rm)
  %m  = add nsw i32 %m1, %m2
  ret i32 %m
}
; CHECK: error{{.*}}lowering: control flow under quantum control
