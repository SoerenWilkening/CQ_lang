; control_predmux_reject_undef_freeze_phi.ll — ACCEPT (dm7f.16.1).
; Existing [0,undef]->0 PHI normalization is a legal refinement.
; Then c=(k==0), g=(q>5) select equality tuples (7,70) on g&&c,
; (9,90) on g&&!c, and (11,110) on !g. Nested classical control
; now has the shared admission argument; borrowed q supplies every compare.
; Historical filename retained.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %k) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  br i1 %c0, label %a, label %sideb
a:
  %c1 = icmp slt i32 %q, 3
  br i1 %c1, label %a1, label %a2
a1:
  br label %b
a2:
  br label %b
b:
  %sp = phi i32 [ 0, %a1 ], [ undef, %a2 ]   ; ← identical only AFTER the freeze
  %cc = icmp eq i32 %sp, %k                  ; ← classical runtime i1 post-RAUW
  br i1 %cc, label %t, label %f
t:
  %vt  = icmp eq i32 %q, 7
  %vt2 = icmp eq i32 %q, 70
  br label %merge
f:
  %vf  = icmp eq i32 %q, 9
  %vf2 = icmp eq i32 %q, 90
  br label %merge
sideb:
  %vs  = icmp eq i32 %q, 11
  %vs2 = icmp eq i32 %q, 110
  br label %merge
merge:                                       ; all-i1 ⇒ BoolAlg, no select minted
  %p1 = phi i1 [ %vt, %t ], [ %vf, %f ], [ %vs, %sideb ]
  %p2 = phi i1 [ %vt2, %t ], [ %vf2, %f ], [ %vs2, %sideb ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %s  = add i32 %z1, %z2
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}


; CHECK-LABEL: define i32 @probe(
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-DAG: icmp eq i32 0, %k
; CHECK-DAG: %[[E7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: %[[E70:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 70)
; CHECK-DAG: %[[E9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 9)
; CHECK-DAG: %[[E90:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 90)
; CHECK-DAG: %[[E11:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 11)
; CHECK-DAG: %[[E110:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 110)
; CHECK: %[[Z1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; CHECK: %[[Z2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; CHECK: %[[SUM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[Z1]], i32 %[[Z2]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[SUM]])
