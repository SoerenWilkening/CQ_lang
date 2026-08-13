; control_predmux_accept_i1phi_final_merge.ll — ACCEPT (3c6m.14 L6 Inc 2,
; Rule-13 judge follow-up): the converting i1 phi sits at the region's FINAL
; merge (R.Merge, the post-dominator — always on the taken path, so the
; exactly-one-EP-true coverage is exact, not merely garbage-masked), with an
; incoming riding the entry's FALSE bypass edge — its term conjoins the
; leaf-inverted entry literal (¬c1 = sle) with a compare defined ABOVE the
; region (the pre-region-value incoming case).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp eq i32 %q, 4
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = icmp eq i32 %q, 7
  br i1 %c2, label %ia, label %ib
ia:
  %ca = icmp slt i32 %q, 3
  br label %merge
ib:
  %cb = icmp sgt i32 %q, 8
  br label %merge
merge:
  %flag = phi i1 [ %c0, %entry ], [ %ca, %ia ], [ %cb, %ib ]
  %v = select i1 %flag, i32 3, i32 9
  %w = add i32 %q, %v
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; flag = (¬c1 ∧ c0) ∨ (c1∧c2 ∧ ca) ∨ (c1∧¬c2 ∧ cb); ¬c1 = sle 5, ¬c2 = ne 7:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 4)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 8)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
