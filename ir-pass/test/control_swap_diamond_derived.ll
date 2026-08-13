; control_swap_diamond_derived.ll — ACCEPT: diamond routing a DERIVED base (pre-region cq_phi).
;
; `q = rz(q, 0.9); if (q > 5) { rz(q, a); rz(q, b); }` — the merge phi's
; straight-through (Pred-edge) incoming AND the arm's spine base are both the
; PRE-REGION `%qd = cq_phi(%q, ·)`: Base == StraightThrough, a DERIVED tainted
; base (§0 criterion 3; test_C_libtooling-9hh). Routing %qd is correct because
; %qd is the LIVE register (the pre-rotation fires unconditionally before the
; region) and Rz is diagonal, so the flag minted from icmp(%qd) is recoverable
; by icmp_inv(%qd) after the arm — same argument as the un-derived diamond, the
; pre-region Rz changes nothing the flag can see.
;
; The diamond used to decline this shape only via the SSA-conservative
; `isPhiCall(Base)` guard (WI-3); the lowered stream is control_swap_diamond.ll
; plus one unconditional `cqrt_rz` strictly BEFORE the flag mint.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): two cqrt_free (work rail + flag), no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
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
; flag mint, then route q into a |0> work rail
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
; route back (adjoint of the split, same %flag), free the |0> rail
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; strip the boolean and reclaim the flag
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
