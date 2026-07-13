; control_predmux_accept_fp_mini_lround.ll — ACCEPT (3c6m.14 L6 Inc 1): the
; lround exit idiom in miniature — fcmp conditions, f64 data merges (kjd1 fp
; select family), `fneg`, and a `fptosi` cast AFTER the merge feeding an i64
; measure. Nested (W1) + 3-incoming phi (W3). Today: `nested control flow
; under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare i64 @cq_measure_sl(i64)

define i64 @probe(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1 = fcmp ogt double %q, 0.000000e+00
  br i1 %c1, label %pos, label %merge
pos:
  %a  = fadd double %q, 5.000000e-01
  %c2 = fcmp ugt double %a, 1.000000e+00
  br i1 %c2, label %big, label %merge
big:
  %b  = fneg double %q
  br label %merge
merge:
  %rm = phi double [ %q, %entry ], [ %a, %pos ], [ %b, %big ]
  %i  = fptosi double %rm to i64
  %m  = call i64 @cq_measure_sl(i64 %i)
  ret i64 %m
}

; fp compares mint fcmp flags with NaN-correct inverse predicates (¬ogt = ule,
; ¬ugt = ole — note the ole leaf compares the SPECULATED %a rail, an HL flag on
; a derived wire); the f64 merges route through the kjd1 fp controlled-copy
; family; the post-merge fptosi lowers via the cast grammar:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fneg_f64(i32 %[[Q]])
; inner select: c1∧¬c2 = ogt(q,0) ∧ ole(a,1) — one Toffoli conjunction:
; CHECK:     %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 0.000000e+00)
; CHECK:     %[[NC2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ole_f64_hl(i32 %[[A]], double 1.000000e+00)
; CHECK:     call void @cqrt_toffoli(i32 %[[C1]], i32 %[[NC2]],
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_copy_f64_controlled(
; outer select: ¬c1 = ule(q,0) picks the raw source over the inner out-rail:
; CHECK:     %[[NC1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ule_f64_hl(i32 %[[Q]], double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[NC1]], i32 %[[Q]],
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[NC1]],
; CHECK:     call i32 @cq_template_fptosi_f64_to_i64(
; CHECK:     call i64 @cqrt_measure_i64(
; CHECK-NOT: br i1
; CHECK-NOT: phi double
; CHECK-NOT: select i1
