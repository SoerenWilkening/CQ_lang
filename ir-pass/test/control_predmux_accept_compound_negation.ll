; control_predmux_accept_compound_negation.ll — ACCEPT (3c6m.14 L6 Inc 1): a
; nested region whose branch condition is a COMPOUND `and i1` of two compares
; (clang's folded `&&`, the tanh/exp/atan idiom). The FALSE edge's literal
; needs ¬(a ∧ b): PredMux pushes the negation to the leaves by De Morgan —
; ¬a ∨ ¬b over inverted-predicate compares — keeping every emitted tree inside
; the 3c6m.12-cleared and/or-over-compare-leaves shape (PRD-3c6m.14 §4.3, the
; no-NOT invariant). Today: `nested control flow under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ca = icmp sgt i32 %q, 1
  %cb = icmp slt i32 %q, 9
  %cc = and i1 %ca, %cb
  br i1 %cc, label %inband, label %merge
inband:
  %v1 = add i32 %q, 1
  %c2 = icmp eq i32 %q, 4
  br i1 %c2, label %four, label %merge
four:
  %v2 = xor i32 %q, 12
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %inband ], [ %v2, %four ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; the false-edge literal materializes as (¬a ∨ ¬b) = (sle 1) or (sge 9):
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 1)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 9)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 1)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 9)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
