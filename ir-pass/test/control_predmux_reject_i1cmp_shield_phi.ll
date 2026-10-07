; control_predmux_reject_i1cmp_shield_phi.ll — ACCEPT (dm7f.16.1).
; The historical q2wk record already verified the emitted network was exact;
; its restriction concerned an unsupported classical admission argument.
; Genuine nested classical conditions now have that argument independently.
; The one-input sp is k's low bit, c=(sp==0), g=(q>5). Each boolean PHI selects
; its compare at q==7/70 on g&&c, q==9/90 on g&&!c, or q==11/110 on !g.
; Edge predicates partition the incoming tuple. The fresh boolean result rails
; preserve q and share a stable classical edge literal on untaken basis arms.
; Filename retained for historical references to the retired fence.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @probe(
; CHECK-DAG: freeze i1
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl
; CHECK: call i32 @cq_template_zext_i1_to_i32
; CHECK: call i32 @cq_template_add_i32(
; CHECK: call i32 @cqrt_measure_i32
; CHECK: ret i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %k) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  %tr = trunc i32 %k to i1               ; off-grammar AND classical
  br i1 %c0, label %a, label %sideb
a:
  br label %b
b:
  %sp = phi i1 [ %tr, %a ]               ; single incoming ⇒ RAUWs to %tr
  %cc = icmp eq i1 %sp, false            ; ← the i1-operand compare SHIELD
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
merge:                                   ; all-i1 phis ⇒ BoolAlg, no select minted
  %p1 = phi i1 [ %vt, %t ], [ %vf, %f ], [ %vs, %sideb ]
  %p2 = phi i1 [ %vt2, %t ], [ %vf2, %f ], [ %vs2, %sideb ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %s  = add i32 %z1, %z2
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
