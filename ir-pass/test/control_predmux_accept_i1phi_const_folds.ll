; control_predmux_accept_i1phi_const_folds.ll — ACCEPT (3c6m.14 L6 Inc 2,
; Rule-13 judge follow-up): the boolean-algebra CONSTANT-fold family. An i1
; phi carrying a const-TRUE incoming (term folds to the bare edge predicate),
; a const-FALSE incoming (term drops entirely — its edge predicate leaves no
; trace in the condition), and a compare incoming (the general EP ∧ v term).
; flag = EP(ia) ∨ (EP(ic) ∧ cc) with EP(ib)'s false term dropped, so the
; consuming select's condition tree carries c1/c2/¬c2/¬c3/cc leaves but NO
; flag for c3's true polarity and nothing for the ib edge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %sideb
inner:
  %c2 = icmp eq i32 %q, 7
  br i1 %c2, label %ia, label %deeper
deeper:
  %c3 = icmp slt i32 %q, 2
  br i1 %c3, label %ib, label %ic
ia:
  br label %ijoin
ib:
  br label %ijoin
ic:
  %cc = icmp sgt i32 %q, 8
  br label %ijoin
ijoin:
  %flag = phi i1 [ true, %ia ], [ false, %ib ], [ %cc, %ic ]
  %v  = select i1 %flag, i32 3, i32 9
  %vv = add i32 %q, %v
  br label %merge
sideb:
  %u = mul i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %vv, %ijoin ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; flag = (c1∧c2) ∨ (c1∧¬c2∧¬c3 ∧ cc); ¬c2 = ne 7, ¬c3 = sge 2:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 2)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 8)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
