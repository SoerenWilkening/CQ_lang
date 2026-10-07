; control_predmux_reject_classical_br_in_region.ll — ACCEPT: nested classical branch (dm7f.16.1).
; The prior q2wk E6-classicalbr fence left this valid program unlowered.
; dm7f.16.1 admits its supported classical condition inside a quantum-rooted
; value region. With g=(q>5), c=(n>3), the captured edge values are q for !g,
; q+1 for g&&!c, and q xor 3 for g&&c. Controlled copies target fresh rails;
; borrowed q stays intact. A stable classical c cannot contaminate !g.
; Filename retained for historical references to the retired fence.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @probe(
; CHECK-DAG: call i32 @cq_template_add_i32_hl
; CHECK-DAG: call i32 @cq_template_xor_i32_hl
; CHECK-DAG: freeze i1
; CHECK: call void @cqrt_copy_i32_controlled
; CHECK: call i32 @cqrt_measure_i32
; CHECK: ret i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %n) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %v1 = add i32 %q, 1
  %cc = icmp sgt i32 %n, 3
  br i1 %cc, label %arm, label %merge
arm:
  %v2 = xor i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %mid ], [ %v2, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
