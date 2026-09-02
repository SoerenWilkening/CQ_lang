; control_swap_diamond_derived.ll — ACCEPT: diamond routing a DERIVED base (pre-region cq_phi).
;
; `q = rz(q, 0.9); if (q > 5) { rz(q, a); rz(q, b); }` — the merge phi's
; straight-through (Pred-edge) incoming AND the arm's spine base are both the
; PRE-REGION `%qd = cq_phi(%q, ·)`: Base == StraightThrough, a DERIVED tainted
; base (§0 criterion 3; test_C_libtooling-9hh). Gating on %qd is correct because
; %qd is the LIVE register (the pre-rotation fires unconditionally before the
; region) and Rz is diagonal, so the flag minted from icmp(%qd) is recoverable
; by icmp_inv(%qd) after the arm — same argument as the un-derived diamond, the
; pre-region Rz changes nothing the flag can see. That argument is about the
; REGISTER, not the route, so it survives the §6a control-in-place collapse
; verbatim: the arm gates now fire as `cqrt_rz_i32_controlled(flag, %qd, ·)`
; directly on the derived base, with no work rail and no CSWAP.
;
; The diamond used to decline this shape only via the SSA-conservative
; `isPhiCall(Base)` guard (WI-3); the lowered stream is control_swap_diamond.ll
; plus one unconditional `cqrt_rz` strictly BEFORE the flag mint. The point of the
; fixture is that the pre-region rotation stays UNCONTROLLED and ahead of the mint,
; while the arm rotations are the controlled ones — the two are distinguishable by
; symbol (`cqrt_rz_i32` vs `cqrt_rz_i32_controlled`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): one cqrt_free (the flag), no second.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)   ; UNCONDITIONAL pre-rotation
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %a)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %qd, %entry ]   ; straight-through = the DERIVED %qd
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; pre-region Rz strictly BEFORE the flag mint
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; flag mint from the DERIVED base
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; arm body: one controlled Rz per arm gate, IN PLACE on the derived base, in
; arm-gate order
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; strip the boolean and reclaim the flag
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
