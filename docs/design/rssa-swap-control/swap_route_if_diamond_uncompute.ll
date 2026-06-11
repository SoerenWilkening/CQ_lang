; swap_route_if_diamond_uncompute.ll — DESIGN SPEC, the uncompute companion
; ===========================================================================
; Revised 2026-06-09. Two things changed vs the original draft of this file:
;
;   * METHOD-A (controlled-adjoint rail cleanup) IS DROPPED. The earlier draft
;     spec'd a `cqrt_rz_i32_controlled` cleanup of the inactive rail as "the
;     coherent path for rotation arms." That is struck: if you would emit a
;     controlled gate to clean a rail, you could have controlled the op in place
;     from the start (§6a), so it buys nothing. For PHASE arms there is no
;     separate uncompute at all — coherence is the cheap `icmp_inv(q)` flag-strip
;     already specified in `swap_route_if_diamond.ll` (SCOPING.md §3a).
;
;   * This file now specs the two uncompute shapes that DO survive:
;       (B-undo)  full-region reverse-play  — the on-demand "undo the whole if"
;                 (user `cq_invert` / oracle uncompute). Well-defined for ANY arm
;                 via the existing EmitInverse spine; shown below on the phase
;                 diamond.
;       (B-keep)  compute → copy-out → reverse-play — VALUE arms only (4.2). Adds
;                 the per-width `cqrt_copy_<W>` (the design's only new ABI;
;                 §7.6 RESOLVED, PRD Part II §8.1). PINNED at 4.2 WI-4 below —
;                 the executable contract is control_swap_value_diamond.ll
;                 (IMPLEMENTATION-4.2 §5d, symbol order IS the contract).
;
; SOURCE INTENT (same diamond as swap_route_if_diamond.ll):
;     q : quantum handle
;     if (q > 5) { rz(q, a); rz(q, b); }   // PHASE arm
;
; KEY IDEA: the forward swap-route is a clean unitary R of self-inverse CSWAP/X
;   plus the arm body. Its inverse R† is the instruction stream REVERSED with each
;   body gate adjointed (CSWAP/X self-inverse; rz(θ)† = rz(-θ); alloc† = free;
;   mint† = `_inv`). Crucially, R† restores q0 BEFORE the flag uncompute, so the
;   data-derived `icmp_inv(q)` is valid for ANY arm class (this is why the
;   2026-06-08 "Ry flag uncompute" §7.3 worry dissolves — SCOPING.md §3a).
; ===========================================================================

; --- INPUT IR (frontend / pre-lowering) — identical to swap_route_if_diamond.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; ===========================================================================
; (B-undo) FULL-REGION REVERSE-PLAY — undo the whole `if` (user `cq_invert`
;   bracket / oracle uncompute). R then R†. After it, q == q0 and every ancilla
;   is |0>. Well-defined for any arm; the engine is the existing EmitInverse.
; ===========================================================================
; declare void @cqrt_cswap(i32, i32, i32)
; declare i32  @cqrt_alloc_i32(i32)
; declare void @cqrt_free(i32)
; declare void @cqrt_rz_i32(i32, double)
; declare i32  @cq_template_icmp_sgt_i32_hl(i32, i32)
; declare i32  @cq_template_icmp_sgt_i32_hl_inv(i32, i32)
;
; define void @example_inverted(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;   ; ----- R : forward swap-route (identical to swap_route_if_diamond.ll, minus
;   ;           the flag-strip + frees — those are folded into R† below)
;   %flag = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %t    = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_rz_i32(i32 %t, double %a)
;   call void @cqrt_rz_i32(i32 %t, double %b)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   ; ----- R† : reverse-play. Same instructions, reversed, each body adjointed.
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_rz_i32(i32 %t, double %sub_b)         ; %sub_b = -b  (undo b first)
;   call void @cqrt_rz_i32(i32 %t, double %sub_a)         ; %sub_a = -a
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)      ; %q is now back to q0
;   call void @cqrt_free(i32 %t)                          ; t == |0>, clean free
;   %f0 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5) ; flag -> |0> (valid: q==q0)
;   call void @cqrt_free(i32 %flag)
;   ; q == q0; t and flag clean and disentangled. The region is fully undone.
;   ret void
; }

; ===========================================================================
; (B-keep) COMPUTE → COPY-OUT → REVERSE-PLAY — VALUE arms only. PINNED at 4.2
;   WI-4 (the §5d contract stream; executable spec control_swap_value_diamond.ll,
;   emitter SwapRouteEmit::emitValueDiamond). For a basis-valued (permutation)
;   arm: run R, copy the basis answer to a fresh register (`cqrt_copy_<W>` —
;   integer widths only, the design's sole new ABI), then reverse-play R† to
;   restore p0 and zero the rail (which makes the trailing icmp_inv valid). WRONG
;   for rz/ry (a CNOT copies a basis label, not a phase; verified P0 0.585->0.500),
;   which is exactly why phase arms use the flag-strip instead, NOT this.
;
; SOURCE INTENT (value diamond; the condition register q is DISJOINT from the
; routed value register p in every accepted region — SCOPING.md §3c):
;     if (q > 5) { p = p*5; p = p+15; }
;
;   %flag = call i32  @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)      ; 1 mint
;   %rail = call i32  @cqrt_alloc_i32(i32 0)                           ; 2 |0> rail
;   call void @cqrt_cswap(i32 %flag, i32 %p, i32 %rail)                ; 3 route-in
;   %v1   = call i32  @cq_template_mul_i32_hl(i32 %rail, i32 5)        ; 4 chain (verbatim,
;   %v2   = call i32  @cq_template_add_i32_hl(i32 %v1, i32 15)         ; 4  uncontrolled)
;   call void @cqrt_cswap(i32 %flag, i32 %p, i32 %v2)                  ; 5 route-back
;   %out  = call i32  @cqrt_alloc_i32(i32 0)                           ; 6 copy target
;   call void @cqrt_copy_i32(i32 %p, i32 %out)                         ; 6 B-keep copy
;   call void @cqrt_cswap(i32 %flag, i32 %p, i32 %v2)                  ; 7 route-back†
;   %u1   = call i32  @cq_template_add_i32_hl_inv(i32 %v2, i32 15)     ; 7 chain adjoint
;   %u2   = call i32  @cq_template_mul_i32_hl_inv(i32 %u1, i32 5)      ; 7 chain adjoint
;   call void @cqrt_cswap(i32 %flag, i32 %p, i32 %u2)                  ; 7 route-in†
;   call void @cqrt_free(i32 %u2)                                      ; 8 rail |0> only AFTER R†
;   %f0   = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)  ; 9 strip (q == q0)
;   call void @cqrt_free(i32 %flag)                                    ; 9 flag free
;   %m    = call i32  @cq_measure_si32(i32 %out)                       ; phi RAUW'd -> out
;
; LOAD-BEARING ORDER: the copy sits AFTER the route-back (the answer is on p
; only then) and BEFORE the route-back† (R† destroys it on p); the rail free
; consumes the FINAL threaded `_inv` handle (%u2 — not %rail/%v2); the strip
; follows R†. EXACTLY TWO frees: %out (the answer) and %p (the restored source)
; are NEVER freed — either free is a hidden measurement. The R† route cswaps
; are emitted by `emitRoute` brackets, NOT through `emitInverseChain` — the
; involution path threads the handle into arg 0, the cswap FLAG slot (the
; EmitInverse seam; PRD Part II §8.5).
;
; NOTE: an arm that value-changes a variable the CONDITION reads is REJECTED
; (SCOPING.md §3c, ACTIVE since 4.2 WI-3, through the routed base's
; diagonal-alias closure) — no copy can disentangle a non-injective result.
; (B-keep) therefore applies to value arms on NON-condition registers. The
; kept-source correlation boundary (|q>|p0>|f(p0)> vs the in-place
; |q>|f(p0)>, observable on channels A/B) is documented in PRD Part II §8.2 —
; binding documentation, not a bug.
