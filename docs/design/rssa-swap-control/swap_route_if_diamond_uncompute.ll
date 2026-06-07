; swap_route_if_diamond_uncompute.ll — DESIGN SPEC, the COHERENT path
; ===========================================================================
; The future (post-v1) coherent lowering of the SAME diamond as
; swap_route_if_diamond.ll. v1 emits the forward swap-route and IGNORES the
; work-register garbage (sound only for terminal/measured outputs). The coherent
; path additionally UNCOMPUTES the ancilla so the region is garbage-free and can
; be re-interfered (Grover/QPE built "on top"). This file specifies that path.
;
; Gated behind the §3 interference guard in SCOPING.md: emitted only when the
; region's output reaches an interfering op before measurement.
;
; SOURCE INTENT (same as swap_route_if_diamond.ll):
;     q : quantum handle
;     if (q > 5) { rz(q, a); rz(q, b); }
;     <result re-interfered later>
;
; KEY IDEA (answer to "is uncompute just playing it in reverse?"):
;   The forward swap-route is a clean unitary R made of self-inverse CSWAP/X plus
;   the arm body. Its inverse R† is the instruction stream REVERSED with each body
;   gate adjointed. Two uses:
;     (A) full inverse  : run R† alone  -> restores q0, zeroes ancillas, DESTROYS
;                         the answer. Use to undo the region as a subroutine.
;     (B) keep answer   : run R ; copy the result out ; run R†  (compute-copy-
;                         uncompute). Reverse-play restores q0 and zeroes t.
;                         *** CLASSICAL-PERMUTATION bodies ONLY (basis-valued
;                         results). WRONG for rz/ry: a CNOT copies a basis label,
;                         not a phase, so R† cancels the phase/superposition that
;                         WAS the answer. For rotations use the in-place method
;                         below. See SCOPING.md §3a. ***
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
; TARGET OUTPUT — method (B): compute -> copy-out -> reverse-play
;   CLASSICAL-PERMUTATION bodies ONLY (add/mul/x/toffoli — basis-valued result).
;   NOT general: WRONG for rz/ry, which it dephases (verified: P0 0.585 -> 0.500).
;   The rz body below shows the MECHANICS only; for a real rz/ry arm the coherent
;   path is the in-place method further down. See SCOPING.md §3a.
; ===========================================================================
; declare void @cqrt_cswap(i32, i32, i32)
; declare i32  @cqrt_alloc_i32(i32)
; declare void @cqrt_free(i32)
; declare void @cqrt_rz_i32(i32, double)
; declare void @cqrt_copy_i32(i32, i32)        ; out ^= src (reversible CB copy = transversal CNOT; NOT cloning)
; declare i32  @cq_template_icmp_sgt_i32_hl(i32, i32)
; declare i32  @cq_template_icmp_sgt_i32_hl_inv(i32, i32)
;
; define i32 @example(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;
;   ; ----- R : forward swap-route (identical to the v1 fixture, minus the free)
;   %flag = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %t    = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_rz_i32(i32 %t, double %a)
;   call void @cqrt_rz_i32(i32 %t, double %b)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)     ; answer now in %q
;
;   ; ----- copy-out : the ONE extra op that lets us keep the answer
;   %out  = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_copy_i32(i32 %q, i32 %out)           ; %out := answer
;
;   ; ----- R† : reverse-play. Same instructions, reversed, each body adjointed.
;   ;       CSWAP and X are self-inverse; rz(θ)† = rz(-θ); alloc† = free; mint† = inv.
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_rz_i32(i32 %t, double %sub_b)         ; %sub_b = -b   (undo b first)
;   call void @cqrt_rz_i32(i32 %t, double %sub_a)         ; %sub_a = -a
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)      ; %q is now back to q0
;   call void @cqrt_free(i32 %t)                          ; t == |0>, clean free
;   %f0 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)  ; flag -> |0> (valid: q==q0)
;
;   ; result lives in %out; %q == q0, %t and %flag are clean and disentangled.
;   %m = call i32 @cq_measure_si32(i32 %out)
;   ret i32 %m
; }
;
; ===========================================================================
; TARGET OUTPUT — in-place + controlled-adjoint cleanup: THE coherent path for
;   ROTATION bodies (keeps a phase/superposition answer; SCOPING.md §3a-A).
;   No copy-out. Keeps the answer in %q. Cleans %t with a controlled-adjoint.
;   The FLAG uncompute via icmp_inv(%q) shown here is valid ONLY for DIAGONAL
;   (basis-preserving) rz, where icmp(%q)==icmp(q0,5). For an off-diagonal ry
;   under a data-derived flag, %q != q0, so the flag must be left dirty
;   (measure-only) or q0 preserved to clean it — open question, SCOPING.md §7.3.
; ===========================================================================
; define i32 @example(i32 %u0, double %a, double %b) {
; entry:
;   %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
;   %flag = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
;   %t    = call i32 @cqrt_alloc_i32(i32 0)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)
;   call void @cqrt_rz_i32(i32 %t, double %a)
;   call void @cqrt_rz_i32(i32 %t, double %b)
;   call void @cqrt_cswap(i32 %flag, i32 %q, i32 %t)      ; answer in %q; garbage in %t on ¬flag
;   ; clean %t: adjoint body controlled on ¬flag (the branch that left garbage)
;   call void @cqrt_x(i32 %flag)
;   call void @cqrt_rz_i32_controlled(i32 %flag, i32 %t, double %sub_b)  ; rz(-b) if ¬flag
;   call void @cqrt_rz_i32_controlled(i32 %flag, i32 %t, double %sub_a)  ; rz(-a) if ¬flag
;   call void @cqrt_x(i32 %flag)
;   call void @cqrt_free(i32 %t)                          ; t clean
;   %f0 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)  ; OK for rz (basis-preserving)
;   %m  = call i32 @cq_measure_si32(i32 %q)
;   ret i32 %m
; }
;
; NOTE: path (B) reuses your existing EmitInverse machinery (rotation-negate /
; _inv / self-adjoint) to produce R† — the uncompute target is exactly the
; verbatim forward stream, so no ChainWalk/FreePoint lineage analysis is needed.
