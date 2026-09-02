; control_swap_diamond_derived_polarity.ll — ACCEPT: derived base × FALSE-successor arm.
;
; The Rule-9 polarity case (clang -O1 canonicalizes `if (u != k)` to
; `icmp eq; br eq, Merge, Arm`, swapping successors) COMPOSED with the derived
; base (test_C_libtooling-9hh): the gate arm is the FALSE successor and both its
; spine base and the merge straight-through are the pre-region %qd. Must lower
; to the IDENTICAL stream as control_swap_diamond_derived.ll except that the arm's
; gate run is ¬flag-bracketed (`cqrt_x(flag)` self-inverse pair), exactly like the
; un-derived control_swap_diamond_polarity.ll. Arms are resolved by merge-phi
; incoming IDENTITY, not edge order.
;
; Under the §6a control-in-place peephole there is nothing to route, so the bracket
; wraps the CONTROLLED gate run — ONE pair, i.e. EXACTLY TWO `cqrt_x` (the route
; needed four, one pair per CSWAP). The composed property being pinned is unchanged:
; derived base × false-successor arm still resolves to the same arm, on ¬flag.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; Independent EXACT ¬flag-bracket count: ONE bracket around the gate run.
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp eq i32 %qd, 5
  br i1 %c, label %merge, label %arm   ; gate arm on the FALSE edge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the arm's gate run under ¬flag: ONE self-inverse X bracket
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; Exact ¬flag-bracket count — two cqrt_x (ONE bracket around the gate run).
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT:     call void @cqrt_x(i32

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
