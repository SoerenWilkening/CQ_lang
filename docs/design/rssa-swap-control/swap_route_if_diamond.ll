; swap_route_if_diamond.ll — DESIGN SPEC for the proposed RSSA swap-routed lowering
; ===========================================================================
; This is the TARGET OUTPUT of the proposed lowering, NOT what `cq-lowering`
; emits today. It lives under docs/design/ (not ir-pass/test/) so it is not run
; as an active test. It graduates to ir-pass/test/ once the swap-route emitter
; exists; the commented RUN/CHECK lines below are the spec it must then satisfy.
;
; Compare against the current controlled-op lowering of the same diamond shape:
;   ir-pass/test/lowering_control_angle_diamond.ll
;
; SOURCE INTENT (one-content-arm diamond, multi-gate arm):
;     q : quantum handle
;     if (q > 5) { rz(q, a); rz(q, b); }
;     measure q
;
; KEY DIFFERENCE FROM TODAY:
;   - today: each arm gate becomes a `_controlled` template, the φ becomes a
;     controlled-rotation-by-difference, and the flag is uncomputed (icmp_inv).
;   - swap-route: mint the flag, CSWAP the operand into a work register, run the
;     arm gates VERBATIM and UNCONTROLLED, CSWAP the result back. The arm body is
;     copied unchanged — no `_controlled` variant required for any gate.
;
; v1 SCOPE (principles, not Grover): the work register is left holding the
; inactive branch's garbage, and the flag ancilla is left dirty. Both are only
; uncomputed on the future COHERENT path. This is sound iff %q is TERMINAL
; (measured) before any cross-branch interference — see SCOPING.md §3.
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
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)   ; arm gate 1
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)   ; arm gate 2
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
;
; define i32 @example(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;   ; br: mint flag from the tainted condition, then route q into a work register
;   ; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
;   ; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
;   ; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
;   %flag = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %t    = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   ; arm body: VERBATIM, UNCONTROLLED gates on the routed register
;   ; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
;   ; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
;   call void @cqrt_rz_i32(i32 %t, double %a)
;   call void @cqrt_rz_i32(i32 %t, double %b)
;   ; phi: route the active result back into q
;   ; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   ; v1: reclaim the work register (its garbage is ignored under measure-only use)
;   ; CHECK:     call void @cqrt_free(i32 %[[T]])
;   call void @cqrt_free(i32 %t)
;   ; NB: NO `cqrt_rz_i32_controlled` and NO `cq_template_icmp_sgt_i32_hl_inv`.
;   ; CHECK-NOT: _controlled
;   ; CHECK-NOT: _hl_inv
;   ; CHECK-NOT: phi i32
;   %m = call i32 @cq_measure_si32(i32 %q)
;   ret i32 %m
; }
