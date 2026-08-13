; control_predmux_accept_i1phi_data.ll — ACCEPT (3c6m.14 L6 Inc 2, Rule-13
; judge follow-up): an i1 phi whose result is used as DATA (zext into
; arithmetic), not as a select condition. The boolean-algebra branch fires on
; incoming SHAPE alone, so the phi still converts to ∨ᵢ (EP(eᵢ) ∧ vᵢ) — but
; this consumer rides a genuinely different lowering path: the and/or i1
; nodes lower as straight-line Q+Q data templates (cq_template_{and,or}_i1)
; and the zext through the cast grammar, with no flag network and no
; controlled copies for the phi itself.
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
  br i1 %c2, label %ia, label %ib
ia:
  %ca = icmp slt i32 %q, 3
  br label %ijoin
ib:
  %cb = icmp sgt i32 %q, 8
  br label %ijoin
ijoin:
  %flag = phi i1 [ %ca, %ia ], [ %cb, %ib ]
  %z  = zext i1 %flag to i32
  %vv = add i32 %q, %z
  br label %merge
sideb:
  %u = mul i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %vv, %ijoin ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_and_i1(
; CHECK-DAG: call i32 @cq_template_or_i1(
; CHECK:     call i32 @cq_template_zext_i1_to_i32(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
