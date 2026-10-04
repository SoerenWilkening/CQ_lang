; control_inplace_ry_stateprep_cond_bitcast_seed.ll — ACCEPT: the SAME-WIDTH
; cross-type seed, i.e. the sharpest case F2's same-type gate lets through.
;
; The seed is `float 0x36C4000000000000` — the float whose 32 BITS ARE THE
; INTEGER 5, i.e. exactly the compare literal's bit pattern at the same width.
; This is the `-O1` image of PLAIN C (measured 2026-09-05, BOTH through a
; `union` and through `memcpy`):
;
;     union { int i; float f; } u;  float r = <bits of 5>;
;     if (q == 5) { u.i = q; r = u.f; cq_theta(&r, 0.9); }
;
; The round-1 review (lens L6, F-L6-1 item (ii)) asked for this to be MEASURED
; rather than argued, because the whole cross-type rationale turns on it: if a
; same-width `bitcast` were an ALIAS — an in-place RAUW, one physical wire —
; then this module WOULD be an in-place Ry on the condition register and F2
; would owe a BIT-PATTERN clause.
;
; IT IS NOT AN ALIAS. MEASURED: the unfolded twin
; (`int q = …; cq_theta(&q, …); union {…} u; u.i = q; cq_theta(&u.f, .9);`) lowers to
;
;     %h_cast = call i32 @cq_template_bitcast_i32_to_f32(i32 %h)
;     call void @cqrt_ry_f32(i32 %h_cast, double 9.000000e-01)
;
; — A FRESH HANDLE. So the int↔fp bitcast is an out-of-place derived rail like
; every other cast, this is the §14.2c accept class, and a bit-pattern clause
; would over-decline a coincidence for nothing. (`foldIdentityBitcasts` folds
; only SAME-WIDTH INT↔INT bitcasts into an identity — and there the two types are
; EQUAL, so F2's ordinary value test already asks the question.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare float @cq_theta_f32(float, double)
declare i32 @cq_measure_si32(i32)
declare float @cq_measure_f32(float)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call float @cq_theta_f32(float 0x36C4000000000000, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi float [ %rt, %arm ], [ 0x36C4000000000000, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call float @cq_measure_f32(float %rm)
  ret i32 %mq
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl({{.*}}, i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float 0x36C4000000000000)
; CHECK-NEXT: call void @cqrt_ry_f32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)

; ---------------------------------------------------------------------------
; ⚠ THE NEGATIVE ASSERTIONS, REGENERATED 2026-09-05 (round-1 Rule-13 review,
; lens L7 findings F-L7-1 / F-L7-2 — the Inc-3 F-L6-1 recurrence).
;
; A POSITIVE directive inside a prefix WINDOWS every negative one of that prefix:
; FileCheck scans a "not" directive only between the previous and the next
; positive match. The shipped Inc-4 blocks put a positive COUNT of `cqrt_free`
; INSIDE the NOROUTE prefix, so every negative after it stopped scanning at the
; FLAG's free — which is exactly where the uncompute spine emits. MEASURED at
; hand-back: an injected `_controlled_inv` after the free was caught by 0 of 20
; NOROUTE blocks (7 of 20 caught it in NO prefix at all). NOROUTE is therefore
; PURE-NEGATIVE and WHOLE-FILE from here on, and every count lives in the CNT
; (or XCNT) prefix, where a positive directive is the point.
;
; THE HANDLE NAMES BELOW ARE THE LOWERED MODULE'S, DERIVED FROM THE PASS OUTPUT
; RATHER THAN TYPED (F-L7-2: 9 of 20 files named a `%h1` that does not exist in
; their own output, so the M7 assertion they carried was vacuous).

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_
; THE FREEZE, whole-file: no `cqrt_free` may EVER name a PREPPED rail. A
; controlled gate's adjoint needs its CONTROL, and the flag is stripped and freed
; inside the region, so emitting one would be a use-after-free of the flag
; followed by a dirty free of a condition-entangled rail (the measured Inc-1
; defect). The rail is LEFT ALLOCATED — Rule 6's sanctioned fallback.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_f32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
