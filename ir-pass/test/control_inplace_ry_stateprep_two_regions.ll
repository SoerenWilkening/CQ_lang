; control_inplace_ry_stateprep_two_regions.ll — ACCEPT: two INDEPENDENT
; sequential state preps on two different registers (PRD §14.3 row A-20; probe
; `p12a`).
;
;     int r = 0, s = 0;
;     if (q == 5) { r = 0; cq_theta(&r, .9); }
;     if (q == 6) { s = 0; cq_theta(&s, .4); }
;
; The bd `hcrg` SEQUENTIAL-region path: region 2's tainted branch lives in
; region 1's MERGE block, so `lowerControlRegions` must Kahn-sort the two before
; emitting (a teardown ORDER bug, not a semantic one). Two preps, two flags, two
; fresh rails, two `cqrt_free`s — and F1 is satisfied INDEPENDENTLY in each
; region because each merge φ's pred incoming is its own `Constant`.
;
; ⚠ CONTRAST WITH `..._reject_stateprep_prep_then_prep.ll`, which is the same
; source with ONE variable: there region 2's pred incoming is region 1's merge
; φ (a value, not a `Constant`), so F1 declines it as a data mux. Same shape,
; different variable, opposite verdict — which is what makes F1 a fence about
; the MERGE rather than about the arm.
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
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %m1
m1:
  %rm = phi i32 [ %rt, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %q, 6
  br i1 %c2, label %arm2, label %m2
arm2:
  %st = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  br label %m2
m2:
  %sm = phi i32 [ %st, %arm2 ], [ 0, %m1 ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %ms = call i32 @cq_measure_si32(i32 %sm)
  %s1 = add i32 %mq, %mr
  %s2 = add i32 %s1, %ms
  ret i32 %s2
}

; two flags, two fresh rails, two frees — and the SOURCE ORDER survives the
; reversed emission order (each emitter inserts positionally into its own pred).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 6)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[S]], double 4.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 6)
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
; NOROUTE-NOT: call void @cqrt_free(i32 %h3)
; …and the arm gate must not become UNCONDITIONAL (mutation M7 — that fires the
; rotation on BOTH branches, the wrong unitary this whole clause exists to
; avoid). Named by HANDLE AND ANGLE together, because an unconditional
; `cqrt_ry_<W>` on the prepped rail at a DIFFERENT angle is a legitimate
; post-region user (`..._then_uncond_theta.ll` has exactly one).
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01)
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h3, double 4.000000e-01)

; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
