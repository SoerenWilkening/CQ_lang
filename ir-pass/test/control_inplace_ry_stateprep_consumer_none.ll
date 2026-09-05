; control_inplace_ry_stateprep_consumer_none.ll — ACCEPT: the prepped register is
; DEAD after the region (PRD §14.3 row A-18). HAND IR — see the warning below.
; The CONSUMER axis is ORTHOGONAL to the fence (PRD §14.3 rows A-13..A-19), and
; it needs its own fixtures for the reason §14.12 worry 8 records: the probe
; family could only measure that the DIAMOND survives `-O1` for each consumer,
; because none of them could COMPILE until the fence existed. "The region then
; lowers for all seven" was INFERRED from Inc 1's identical family, and the DER
; lesson says an inferred accept is exactly where a vacuous one hides.
;
; What every row shares: the prepped rail is FROZEN
; (`ChainWalk::railCarriesControlledRotation`), so no consumer may cause an
; adjoint or a `cqrt_free` of it — the O(1) leak is the Rule-6-sanctioned
; fallback, and a free would be a dirty free of a condition-entangled rail.
;
; ⚠ `clang -O1` DOES NOT PRODUCE THIS MODULE EITHER (measured 2026-09-04, probe
; `p13g`; PRD §14.3 row A-18 is CORRECTED). With `r` genuinely dead the merge φ
; is DELETED outright, so no `BranchRegion` forms at all and the tainted `br`
; falls to the generic decline — for BOTH arm classes (the `--stateprep` matrix
; cell `sp_s0_eq_diamond_none_i32` reads DECLINE-BOTH, before and after Inc 4).
; This file keeps the φ, which is what a caller-supplied `.ll` presents, and that
; is what lets it ask the question the C program cannot: with a live φ and no
; consumer, does the whole-DAG spine reverse and free the prepped rail?
;
; THIS IS THE ROW THAT ACTUALLY TESTS THE FREEZE, and it is the state-prep twin
; of `control_inplace_ry_dead_base_frozen.ll`. A dead tainted handle is exactly
; what the whole-DAG LIFO spine exists to reverse-play and free; the freeze is
; what stops it, and it is asked STRUCTURALLY of the emitted gate
; (`ChainWalk::railCarriesControlledRotation` derives the rail from the gate's
; own arg-1 use) rather than from a `Value *` set — the Inc-1 round-1 fix,
; because a set keyed at `lowerRotations` time dangles the moment `lowerOps`
; RAUWs and erases a derived base.
;
; If the freeze ever stops applying here the failure is NOT verify-visible: the
; spine would emit `cqrt_ry_i32_controlled_inv(f, h, θ)` naming a flag that was
; stripped and freed three instructions earlier (a use-after-free) and then a
; `cqrt_free` of a rail entangled with a register that no longer exists — the
; measured Inc-1 defect, verbatim.
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
  %mq = call i32 @cq_measure_si32(i32 %q)
  ret i32 %mq
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

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
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
