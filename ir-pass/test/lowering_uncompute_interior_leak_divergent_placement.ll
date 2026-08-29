; lowering_uncompute_interior_leak_divergent_placement.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc). INVARIANT 7: the discharge must be
; placed where the rail is dead on EVERY path — never inside a divergent arm.
;
; `%h_op` is minted in `entry`, on every path, and its ONLY consumer sits inside
; the classical `if` arm `%T`. The anchor set is therefore entirely inside `%T`
; and `dagInsertPoint`'s nearest common POST-dominator of the anchors is `%T`
; itself — a block that does NOT post-dominate `entry`. Placing the reversal
; there would adjoint-and-free on one path a rail that was minted on both.
;
; NOTHING IS FREED DIRTY BY THAT — the other path simply leaks — so this is not
; the reverted-543bd85 divergent-arm miscompile in the other direction; it is the
; weaker property that `DT.dominates(G, At)` alone does NOT give you. Dominance
; says the gate ran on every path that REACHES the discharge and is silent about
; the paths that do not. The explicit `PDT.dominates(At->getParent(),
; G->getParent())` test is what turns "post-dominator discipline" from the name of
; a helper into a checked property.
;
; A LEAK, NOT A DECLINE: `opt` exits 0 and the whole-DAG spine's own
; `kMsgDivergentArm` is NOT what fires here (that message is for a GATE in an arm
; and a reversal at the merge — the mirror image). M-B is leak-first throughout.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_divergent(i32 %u0, i1 %cond) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  br i1 %cond, label %T, label %F
T:
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  br label %M
F:
  br label %M
M:
  ret i32 0
}

; CHECK-LABEL: define i32 @leak_divergent(
; CHECK: call i32 @cq_template_mul_i32_hl
; CHECK: call i32 @cq_template_icmp_slt_i32_hl
; CHECK: call i32 @cq_template_zext_i1_to_i32
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: _unc
; CHECK-NOT: call void @cqrt_free
