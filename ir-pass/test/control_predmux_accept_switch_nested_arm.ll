; control_predmux_accept_switch_nested_arm.ll — ACCEPT (3c6m.14 L6 Inc 1): a
; tainted 3-way `switch` whose CASE ARM hosts a further tainted branch — the
; mini-scalbn shape (SwitchClassify G11 declines it today as `control flow
; under quantum control`). PredMux converts case edges to eq-compares, the
; default edge to an AND of ne-compares, and the nested arm's edge predicates
; to Toffoli conjunctions (PRD-3c6m.14 §4.3).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %dflt [
    i32 0, label %case0
    i32 7, label %case7
  ]
case0:
  %a0 = add i32 %q, 10
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %case0b, label %merge
case0b:
  %a1 = xor i32 %q, 3
  br label %merge
case7:
  %a2 = mul i32 %q, 5
  br label %merge
dflt:
  %a3 = add i32 %q, 1
  br label %merge
merge:
  %rm = phi i32 [ %a0, %case0 ], [ %a1, %case0b ], [ %a2, %case7 ], [ %a3, %dflt ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The 4-way merge lowers to a 3-select chain; the default arm is the chain
; FALLBACK so its ne-AND predicate is dead-swept — only eq flags appear:
;   out   = (q==7)          ? a2 : a3
;   out4  = (q==0 ∧ q<9)    ? a1 : out
;   out10 = (q==0 ∧ q≥9)    ? a0 : out4
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[E7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[E7]],
; CHECK:     call void @cqrt_x(i32 %[[E7]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[E7]],
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[E7]], i32 %[[Q]], i32 7)
; CHECK:     %[[E0A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 9)
; CHECK:     call void @cqrt_toffoli(i32 %[[E0A]],
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 9)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: switch i32
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
