; control_predmux_reject_equal_incomings_phi.ll — ACCEPT: equal incoming classical phi (dm7f.16.1).
; The historical q2wk fence refused a false prediction of phi taint.
; dm7f.16.1 admits the genuinely classical condition after the equal-value
; phi reduces to arg. Splitting g=(q>5) by q<100 does not change the incoming
; arg. With c=(arg==0), edge values are q for g&&c, q*7 for g&&!c, q+3 for !g.
; PredMux sums incoming edge predicates and captures values before selecting
; into fresh rails. Its classical literal stays stable; borrowed q survives.
; Filename retained for historical references to the retired fence.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @probe(
; CHECK-DAG: call i32 @cq_template_mul_i32_hl
; CHECK-DAG: call i32 @cq_template_add_i32_hl
; CHECK-DAG: freeze i1
; CHECK: call void @cqrt_copy_i32_controlled
; CHECK: call i32 @cqrt_measure_i32
; CHECK: ret i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %arg) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %A, label %B

A:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %A1, label %A2

A1:
  br label %A3
A2:
  br label %A3

A3:                                    ; 2 unique preds, ONE distinct value
  %ph = phi i32 [ %arg, %A1 ], [ %arg, %A2 ]
  %cc = icmp eq i32 %ph, 0             ; classical RUNTIME condition after RAUW
  br i1 %cc, label %J, label %Ag

Ag:
  %ga = mul i32 %q, 7
  br label %J

B:
  %b = add i32 %q, 3
  br label %J

J:
  %r = phi i32 [ %ga, %Ag ], [ %q, %A3 ], [ %b, %B ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
