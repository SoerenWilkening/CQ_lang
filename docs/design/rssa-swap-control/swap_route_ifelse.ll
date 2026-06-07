; swap_route_ifelse.ll — DESIGN SPEC for the proposed RSSA swap-routed lowering
; ===========================================================================
; The two-arm (if/else) generalisation of swap_route_if_diamond.ll. Both arms
; act on the live handle, so the operand is routed to a DISTINCT work register
; per arm; each arm body runs uncontrolled on its own register; the φ routes the
; active result back. This is the IR transcription of the simulator's Demo A
; (docs/design/rssa-swap-control/prototype_semantics.py), which confirmed it
; reproduces the controlled-op measurement statistics to 3e-16.
;
; SOURCE INTENT:
;     q : quantum handle
;     if (q > 5) { rz(q, a); } else { rz(q, b); }
;     measure q
;
; Routing uses a `cqrt_x(flag)` bracket to express the ¬flag (else) control,
; exactly as the current mux lowering does (lowering_control_mux_handles_i32.ll).
; NOT emitted by today's pass; lives under docs/design/ as a spec. See SCOPING.md.
; ===========================================================================

; --- INPUT IR (frontend / pre-lowering) -----------------------------------
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %q, double %a)    ; then-arm gate
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %q, double %b)    ; else-arm gate
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]      ; q after if = c ? qt : qe
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; --- SWAP-ROUTE TARGET OUTPUT (what the new lowering must emit) ------------
; declare void @cqrt_cswap(i32, i32, i32)
; declare i32  @cqrt_alloc_i32(i32)
; declare void @cqrt_free(i32)
; declare void @cqrt_rz_i32(i32, double)
; declare void @cqrt_x(i32)
; declare i32  @cq_template_icmp_sgt_i32_hl(i32, i32)
;
; define i32 @example(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;   %flag = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %t    = call i32 @cqrt_alloc_i32(i32 0)        ; then work register
;   %e    = call i32 @cqrt_alloc_i32(i32 0)        ; else work register
;   ; br: route q -> t iff flag, q -> e iff ¬flag
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_x(i32 %flag)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %e)
;   call void @cqrt_x(i32 %flag)
;   ; arm bodies: VERBATIM, UNCONTROLLED
;   call void @cqrt_rz_i32(i32 %t, double %a)      ; then body
;   call void @cqrt_rz_i32(i32 %e, double %b)      ; else body
;   ; phi: route the active result back into q (inverse routing)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_x(i32 %flag)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %e)
;   call void @cqrt_x(i32 %flag)
;   ; v1: reclaim both work registers (inactive-arm garbage ignored, measure-only)
;   call void @cqrt_free(i32 %t)
;   call void @cqrt_free(i32 %e)
;   %m = call i32 @cq_measure_si32(i32 %q)
;   ret i32 %m
; }
;
; Note the symmetry: br and phi are the SAME two CSWAP-pairs, applied forward and
; then in reverse. That is the RSSA "phi on both splits and joins" property made
; concrete — the join is literally the adjoint of the split, sharing %flag.
