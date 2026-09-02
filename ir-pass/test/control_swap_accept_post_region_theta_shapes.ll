; control_swap_accept_post_region_theta_shapes.ll — ACCEPT (bd
; test_C_libtooling-lom0 Increment 4): the two OTHER flat phase-arm topologies,
; each with a post-region chained `cq_theta`.
;
; control_swap_accept_post_region_theta.ll pins the ordinary DIAMOND and
; control_swap_accept_post_region_theta_shared_rail.ll the one-rail case. The
; accept set is defined by ARM CLASS (phase), not by diamond shape, so the two
; remaining shapes that `classifyArms` calls a phase arm must be pinned too —
; otherwise a future narrowing could drop one of them silently.
;
;   @ifelse       TWO content arms, one shared routed base. `emitRegion` routes
;                 BOTH arms — two work rails, the ¬flag arm `cqrt_x`-bracketed —
;                 and still emits ONE flag, ONE strip and ONE flag free, all
;                 before the post-region Ry.
;   @derived_base The routed base is a PRE-REGION `cq_phi` (an Rz applied
;                 unconditionally before the branch — the 9hh derived-base
;                 accept). Rz is DIAGONAL, so it leaves no basis record of the
;                 wire and rotation lowering RAUWs `%q` and `%qd` to the SAME
;                 handle; the post-region Ry then lands on that handle. This is
;                 the shape most likely to be confused with the DERIVED-CONDITION
;                 one, which declines — see the contrast below.
;
; THE CONTRAST THAT MATTERS. A derived BASE is a diagonal rotation and is fine; a
; derived CONDITION (`sqrt(a+3.0) <= 5.0`) builds template rails, and until M-B
; Increment 6 they survived the flag strip and the program declined at the
; live-record guard. It ACCEPTS now — the emitter records its strip, the interior
; partition discharges the chain right after it, and the guard reads that as a
; fact (control_swap_accept_post_region_theta_derived_cond.ll, renamed from
; ..._reject_...). The contrast this file draws is UNCHANGED, because it was never
; about the word "derived": the question is whether anything the region touched is
; still an allocated, entangled RECORD of the wire when the Ry fires. Here nothing
; is — and the derived-condition file now answers the same way for the same
; reason, by the chain being discharged rather than by it never existing. The
; shapes that still decline are the ones whose chain M-B cannot discharge (a
; non-diagonal write on the wire inside the interval; a strip no emitter
; recorded). Here nothing is —
; both functions lower to one data register plus per-arm work rails, and every
; rail and flag is freed before the `cqrt_ry_i32`.
;
; Two functions in one module deliberately: `opt` exits non-zero if EITHER
; declines, and one spawn is the whole cost of a lit fixture (the pass itself is
; ~5ms).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ifelse(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %t, label %f

t:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge

f:
  %g2 = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge

merge:
  %p = phi i32 [ %g1, %t ], [ %g2, %f ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

define i32 @derived_base(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.250000e-01)   ; pre-region Rz
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge

merge:
  %p = phi i32 [ %g, %arm ], [ %qd, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; ---- @ifelse: one flag, both arms controlled IN PLACE, ¬flag arm X-bracketed
; (drbq Inc 2a — the two work rails went with the route) ----
; CHECK-LABEL: define i32 @ifelse
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %a)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; ---- @derived_base: the pre-region Rz stays an ordinary unconditional gate on
; the SAME handle the region routes and the post-region Ry rotates ----
; CHECK-LABEL: define i32 @derived_base
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[H2]], double 1.250000e-01)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H2]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H2]], double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[H2]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H2]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; TWO allocations across the module — one register per function. Since drbq Inc
; 2a a phase region mints no work rail (it was five before: +2 rails for @ifelse,
; +1 for @derived_base), and the two registers are measured, so nothing is left
; allocated that was not.
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(

; No swap route survives in either function — window is the first `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
