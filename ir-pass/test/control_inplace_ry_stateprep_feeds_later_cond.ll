; control_inplace_ry_stateprep_feeds_later_cond.ll — ACCEPT: a LATER region whose
; CONDITION IS READ FROM THE PREPPED RAIL.
;
; ⚠ A NEW ACCEPT CLASS THAT SHIPPED WITH NO FIXTURE, NO §14.3 ROW AND NO SLICE
; (round-1 Rule-13 review, lens L3 finding F-1, probe `p/l48_cond_is_prepped_arm_q.c`):
;
;     int q = 3; cq_theta(&q, .3);  int r = 0;
;     if (q == 5) { r = 0; cq_theta(&r, .9); }  /* region 1 — the state prep      */
;     if (r == 1) cq_theta(&q, .2);      /* region 2 — flag MINTED FROM r  */
;
; This is the FIRST shape in which a freshly-minted, condition-entangled rail
; lands in ANOTHER region's flag-mint slot — i.e. the first place
; `lowerCompareToFlag` reads a register whose only producer is a CONTROLLED gate.
; The pre-Inc-4 binary declines it (`condition predates a non-diagonal gate`).
;
; WHY IT IS SOUND, and the argument is about BASIS LABELS rather than about
; entanglement: `f2 = [h2 == 1]` is a basis-DIAGONAL read of the prepped rail
; `h2`; region 2's arm moves `h0` (the ORIGINAL register) and never touches `h2`;
; so the strip `icmp_eq_i32_hl_unc(f2, h2, 1)` recomputes the predicate over an
; UNMOVED register and returns `f2` to |0>, and the free is clean. That holds
; even though `h2` is entangled with `h0`, because the strip depends only on
; `h2`'s basis label, not on its amplitude. Region 2 is a CHAINED arm, so
; `StatePrep` is false for it and R4/R6 run normally over the real
; `railWireClosure` — the two wires are disjoint and R4 proves it.
;
; Measured strict stage 2b on the C original: `4 verified, 0 violations,
; 0 unproven`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %c2 = icmp eq i32 %rm, 1
  br i1 %c2, label %arm2, label %merge2
arm2:
  %qt = call i32 @cq_theta_si32(i32 %q, double 2.000000e-01)
  br label %merge2
merge2:
  %qm = phi i32 [ %qt, %arm2 ], [ %q, %merge ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq = call i32 @cq_measure_si32(i32 %qm)
  %s  = add i32 %mr, %mq
  ret i32 %s
}

; region 1 — the state prep, on a rail this region mints
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; region 2 — the flag is minted FROM THE PREPPED RAIL and stripped over it
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[R]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[Q]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[R]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])

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
; NOROUTE-NOT: call void @cqrt_free(i32 %h2)
; NOROUTE-NOT: call void @cqrt_free(i32 %h)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01)
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h, double 2.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
