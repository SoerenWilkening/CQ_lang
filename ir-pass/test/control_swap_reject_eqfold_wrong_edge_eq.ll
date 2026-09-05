; control_swap_reject_eqfold_wrong_edge_eq.ll — D8 POLARITY decline, `icmp eq`
; with the const-folded arm on the FALSE successor (bd test_C_libtooling-ogw2).
;
; WHAT THE SHAPE MEANS. The compare is `q == 7` and the gate arm is the FALSE
; successor, so the arm is the `q != 7` region — the one edge on which `q` is
; PROVABLY NOT 7. Its gate `cq_phi(i32 7, θ)` therefore does NOT const-fold from
; `q`: it rotates the LITERAL 7 and the merge takes that value, i.e. the source
; says "when q != 7, throw q away and take the phase-rotated constant 7". That is
; a VALUE CLOBBER, not a phase on `q`. Re-anchoring the gate to `q` (which is
; what `tryEqFoldArm`'s ACCEPT does) names the wrong basis and emits a controlled
; Rz on `q` for exactly the branch on which the source never rotates `q` at all —
; a verify-clean WRONG UNITARY, invisible to `opt -verify` and to the trace.
;
; WHY HAND-IR ONLY. `clang -O1` reaches a const-folded arm gate only by proving
; the equality holds INSIDE the arm, so it can never emit this pairing; and it
; also value-propagates the straight-through incoming to a constant, at which
; point the region declines elsewhere. The over-accept is therefore hand-IR
; reachable only — but the decline is what the shape is owed either way (Prime
; Directive: over-declining is always safe, over-accepting is a silent
; miscompile), so it is fenced rather than argued away.
;
; MEASURED ON THE PRE-FIX BINARY (HEAD 24bb42d): this module LOWERED, `opt` exit
; 0, emitting
;     %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 7)
;     call void @cqrt_x(i32 %h_cmp)
;     call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double %a)
;     call void @cqrt_x(i32 %h_cmp)
;     call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 7)
;     call void @cqrt_free(i32 %h_cmp)
; — the ¬flag-bracketed Rz on `%h`, i.e. a phase applied to `q` precisely when
; `q != 7`. D1–D7 all held (equality predicate · folded ConstantInt base · the
; icmp's non-const operand IS the routed handle · literal 7 == folded 7 · tainted
; · pure spine · classical angle); the missing clause was WHICH EDGE. D8 asks it.
;
; The VALID negated shape is `control_swap_eqfold_polarity.ll` (`icmp ne` + arm
; on the FALSE successor = the `q == 7` region) and it must stay ACCEPTING —
; polarity is a proof obligation, not a preference for a true successor.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; No region may be emitted: neither the drbq Inc-2a control-in-place form nor the
; pre-2a swap route.
; CHECK-NOT: cqrt_rz_i32_controlled
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %merge, label %arm     ; arm = FALSE successor: `q != 7` holds there
arm:
  call void @cq_phi(double %a)  ; NOT a fold of q — q != 7 here
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
