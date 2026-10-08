; control_predmux_reject_i1phi_entry_block.ll — ACCEPT (dm7f.16.1).
; The classical entry PHI remains a scalar literal. Let H=(q>5),
; C=g, and A=C?q+1:3q. The measured result is H?(2*A+7):q.
; Shared nested classical conditions admit C; the entry PHI is not a rail.

; Historical filename retained.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %g  = icmp sgt i32 %u0, 0            ; classical (arg-derived): roots no claim
  br i1 %g, label %pa, label %pb
pa:
  br label %rentry
pb:
  br label %rentry

rentry:                                ; ← the CLAIMED region entry (tainted %ct)
  %ep = phi i1 [ true, %pa ], [ false, %pb ]   ; ← the ENTRY-BLOCK phi
  %ct = icmp sgt i32 %q, 5
  br i1 %ct, label %arm, label %merge
arm:
  br i1 %ep, label %t, label %f        ; ← entry phi as an interior branch cond
t:
  %vt = add i32 %q, 1
  br label %ajoin
f:
  %vf = mul i32 %q, 3
  br label %ajoin
ajoin:
  %av = phi i32 [ %vt, %t ], [ %vf, %f ]
  %aw = add i32 %av, 7
  br label %merge

merge:                                 ; 2 merge phis = the PredMux claim witness
  %rm = phi i32 [ %av, %ajoin ], [ %q, %rentry ]
  %rn = phi i32 [ %aw, %ajoin ], [ 0, %rentry ]
  %sum = add i32 %rm, %rn
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}


; CHECK-LABEL: define i32 @probe(
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK: br i1 %g, label %pa, label %pb
; CHECK: rentry:
; CHECK: %ep = phi i1 [ true, %pa ], [ false, %pb ]
; CHECK-DAG: %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 1)
; CHECK-DAG: %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %[[G:[a-zA-Z0-9_.]+]], i32 %[[ADD]], i32 %[[A:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[MUL]], i32 %[[A]])
; CHECK: call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 7)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[Q]],
; CHECK: call i32 @cq_template_add_i32(
; CHECK: call i32 @cqrt_measure_i32(
