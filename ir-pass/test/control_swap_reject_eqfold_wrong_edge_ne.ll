; control_swap_reject_eqfold_wrong_edge_ne.ll — D8 POLARITY decline, `icmp ne`
; with the const-folded arm on the TRUE successor (bd test_C_libtooling-ogw2).
;
; The `icmp eq` twin of control_swap_reject_eqfold_wrong_edge_eq.ll, one polarity
; over. `tryEqFoldArm`'s D1 predicate covers BOTH equality spellings, so the
; wrong-edge hole had two mouths and needs two fixtures: `eq` proves `H == k` on
; its TRUE edge, `ne` on its FALSE edge, and each accepts a fold only there.
;
; WHAT THE SHAPE MEANS. The compare is `q != 7` and the gate arm is the TRUE
; successor, so the arm is again the `q != 7` region — `q` is provably NOT 7
; there. `cq_phi(i32 7, θ)` rotates the LITERAL and the merge takes it: a VALUE
; CLOBBER (when q != 7, discard q and take the rotated constant 7), not a phase
; on `q`. Re-anchoring the gate to `q` names the wrong basis and puts a
; controlled Rz on `q` on exactly the branch where the source does not rotate it.
;
; WHY HAND-IR ONLY. `clang -O1` const-folds an arm gate only where it has PROVED
; the equality holds inside that arm, so it cannot produce this pairing; it also
; folds the straight-through incoming, after which the region declines elsewhere.
; Hand-IR reachable only — and still owed a loud decline (Prime Directive).
;
; MEASURED ON THE PRE-FIX BINARY (HEAD 24bb42d): this module LOWERED, `opt` exit
; 0, emitting
;     %h_cmp = call i32 @cq_template_icmp_ne_i32_hl(i32 %h, i32 7)
;     call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double %a)
;     call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp, i32 %h, i32 7)
;     call void @cqrt_free(i32 %h_cmp)
; — an UNBRACKETED controlled Rz (the arm is the true successor, so `ArmNegated`
; is false and no `cqrt_x` pair appears), i.e. a phase on `q` exactly when
; `q != 7`. D1–D7 all held; the missing clause was WHICH EDGE.
;
; @ifelse_ne in control_swap_eqfold_ifelse.ll is the VALID `icmp ne` shape (the
; folded arm on the FALSE successor) and must stay ACCEPTING.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; No region may be emitted: neither the drbq Inc-2a control-in-place form nor the
; pre-2a swap route.
; CHECK-NOT: cqrt_rz_i32_controlled
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ne i32 %q, 7
  br i1 %c, label %arm, label %merge     ; arm = TRUE successor: `q != 7` holds there
arm:
  %q1 = call i32 @cq_phi_si32(i32 7, double %a)  ; NOT a fold of q — q != 7 here
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
