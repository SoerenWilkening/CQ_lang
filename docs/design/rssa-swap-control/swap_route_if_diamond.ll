; swap_route_if_diamond.ll — DESIGN SPEC for the RSSA swap-routed lowering
; ===========================================================================
; This is the TARGET OUTPUT of the swap-route lowering, NOT what `cq-lowering`
; emits today. It lives under docs/design/ (not ir-pass/test/) so it is not run
; as an active test. It graduates to ir-pass/test/ once the swap-route emitter
; exists; the commented RUN/CHECK lines below are the spec it must then satisfy.
;
; Compare against the removed controlled-op lowering of the same diamond shape
; (recoverable from git history pre-7cde677).
;
; SOURCE INTENT (one-content-arm diamond, multi-gate PHASE arm):
;     q : quantum handle
;     if (q > 5) { rz(q, a); rz(q, b); }   // cq_phi == Rz, a PHASE arm
;     measure q
;
; KEY POINTS (revised 2026-06-09 — coherent, zero controlled gates):
;   - Mint the flag from the tainted condition (the icmp becomes the `_hl` DATA
;     template, producing an i32 flag handle).
;   - CSWAP the operand into a |0> work rail, run the arm Rz gates VERBATIM and
;     UNCONTROLLED on the rail, CSWAP the result back (the phi is the adjoint of
;     the split, sharing %flag).
;   - Rz = diag(1, e^{iθ}) ⇒ Rz|0> = |0>, so the inactive rail returns to |0>
;     UNCONDITIONALLY → clean `free` (a no-op reset, NOT a hidden measurement).
;   - Rz preserves q's computational-basis VALUE, so the flag (icmp(q0)) is still
;     true of the current q: `icmp_inv(q)` strips it back to |0> — NO controlled
;     gate, NO preserved q0. q is left with the conditional phase, fully
;     disentangled and interference-safe (Grover-correct). See SCOPING.md §3a.
;   - NO `_controlled` template anywhere; NO eager reverse-play (that is the
;     on-demand undo for user `cq_invert` / value arms — §3a). NO added measure.
; ===========================================================================

; --- INPUT IR (frontend / pre-lowering) -----------------------------------
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)   ; arm gate 1 (Rz)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)   ; arm gate 2 (Rz)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]       ; q after if = c ? q2 : q
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; --- SWAP-ROUTE TARGET OUTPUT (what the new lowering must emit) ------------
; ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; declare void @cqrt_cswap(i32, i32, i32)
; declare i32  @cqrt_alloc_i32(i32)
; declare void @cqrt_free(i32)
; declare void @cqrt_rz_i32(i32, double)
; declare i32  @cq_template_icmp_sgt_i32_hl(i32, i32)
; declare i32  @cq_template_icmp_sgt_i32_hl_inv(i32, i32)
;
; define i32 @example(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;   ; br: mint the flag, then route q into a |0> work rail
;   ; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
;   ; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
;   ; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
;   %flag  = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %arm.t = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %arm.t)
;   ; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail
;   ; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
;   ; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
;   call void @cqrt_rz_i32(i32 %arm.t, double %a)
;   call void @cqrt_rz_i32(i32 %arm.t, double %b)
;   ; phi: route the active result back into q (adjoint of the split, same %flag)
;   ; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %arm.t)
;   ; rail is |0> (Rz|0>=|0>): clean free — NOT a measurement
;   ; CHECK:     call void @cqrt_free(i32 %[[T]])
;   call void @cqrt_free(i32 %arm.t)
;   ; strip the boolean: q==q0 (Rz preserves basis value), so icmp_inv(q) returns
;   ; the flag to |0>; reclaim it. ZERO controlled gates, NO preserved q0.
;   ; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
;   ; CHECK:     call void @cqrt_free(i32 %[[F]])
;   %flag0 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)
;   call void @cqrt_free(i32 %flag)
;   ; NB: NO `cqrt_rz_i32_controlled`, NO eager reverse-play, NO phi, NO new measure.
;   ; CHECK-NOT: _controlled
;   ; CHECK-NOT: phi i32
;   %m = call i32 @cq_measure_si32(i32 %q)
;   ret i32 %m
; }
