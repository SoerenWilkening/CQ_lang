; control_predmux_reject_degenerate_phi_classical.ll — ACCEPT: degenerate classical phi (dm7f.16.1).
; The historical q2wk fence correctly refused a false prediction of taint.
; dm7f.16.1 now admits genuine nested classical conditions independently of
; that prediction. The one-input phi stays classical when replaced by arg;
; it is frozen as an edge literal. With g=(q>5), c=(arg==0), edge values are
; q for g&&c, q*7 for g&&!c, and q+3 for !g. Copy transfers preserve q.
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
  br label %A2

A2:                                               ; single predecessor
  %ph = phi i32 [ %arg, %A ]                      ; degenerate 1-incoming phi
  %cc = icmp eq i32 %ph, 0                        ; classical RUNTIME condition
  br i1 %cc, label %J, label %Ag

Ag:
  %ga = mul i32 %q, 7
  br label %J

B:
  %b = add i32 %q, 3
  br label %J

J:
  %r = phi i32 [ %ga, %Ag ], [ %q, %A2 ], [ %b, %B ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
