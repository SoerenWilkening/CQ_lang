; control_predmux_accept_i1phi_cond.ll — ACCEPT (3c6m.14 L6 Inc 2): an i1 PHI
; at an internal merge whose incomings are compare leaves, feeding a select
; CONDITION (the tanh s_expm1.c:168 shape: `k = invln2*x+((xsb==0)?0.5:-0.5)`
; where xsb==0 reaches the ternary through a two-edge phi). Inc 1 converted
; every phi to a select chain, so the muxed condition became an i1 SELECT —
; off the 3c6m.12 and/or-over-compare-leaves grammar — and the consuming
; select declined `control flow under quantum control`. Inc 2 converts a
; grammar-conforming i1 phi to boolean algebra instead — ∨ᵢ (EP(eᵢ) ∧ vᵢ) —
; so the condition stays a compare/and-or tree the substrate can flag-mint.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
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

; %flag becomes or(and(c1∧c2, ca), and(c1∧¬c2, cb)) — five compare-leaf flags
; (¬c2 by inverse predicate, the no-NOT invariant), Toffoli/OR-network nodes,
; then the select data merges route via controlled copies:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 8)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
