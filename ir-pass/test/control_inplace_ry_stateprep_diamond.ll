; control_inplace_ry_stateprep_diamond.ll — ACCEPT spec, CONTROLLED STATE PREP,
; the flagship diamond (control-in-place-PRD §14, bd test_C_libtooling-drbq
; Inc 4).
;
;     int q = cq_theta(3, .3); int r = 0;
;     if (q == 5) r = cq_theta(0, .9);       // arg-0 is a CLASSICAL constant
;
; The arm's `cq_theta` has a CLASSICAL arg-0, so it does not rotate a live
; register — it MINTS one. `lowerRotations` takes its `!Chained` arm
; (`cqrt_alloc_i32(0)`) at the theta's HOISTED position and then mints
; `cqrt_ry_i32_controlled(f, h, θ)` instead of the unconditional gate.
;
; THE PHYSICS (PRD §14.1). On the f=0 component the fresh rail is never touched,
; so it holds |SEED>, which — by F1, the seed-identity fence — is exactly the
; value the source's `r` has on the straight-through edge. On f=1 it holds
; Ry(θ)|SEED>. The flag strip `icmp_..._unc` recomputes the predicate on the
; CONDITION's registers and XORs it back; that is valid here WITHOUT R4, because
; the rotated rail is one the compiler minted INSIDE this region and is disjoint
; from every condition wire BY CONSTRUCTION rather than by proof (§14.5 — this is
; the one place Inc 4 is easier than Inc 1, not harder).
;
; The swap route cannot carry this either: Ry(θ)|0> != |0> hands the inactive
; work rail back DIRTY and ENTANGLED (Rules 6/8), so control-in-place is the
; MECHANISM. The prepped rail is then FROZEN by Inc 1's structural freeze
; (`ChainWalk::railCarriesControlledRotation`, which asks the emitted gate's own
; arg-1 use): never reverse-played, never freed — a controlled gate's adjoint
; needs its control and the flag is stripped and freed inside the region. The
; leak is O(1) per region and is the Rule-6-sanctioned fallback.
;
; M-β IS A CORRECTNESS REQUIREMENT HERE, not the loop-bookkeeping convenience it
; is for Inc 3: the emitter RAUWs the merge φ to the hoisted theta T (which
; `lowerRotations` then RAUWs to the fresh alloc handle). The Rz stem's M-α
; (RAUW to the BASE) would RAUW the merge to the CONSTANT SEED and every consumer
; of `r` would become a classical literal — a silently classical program.
;
; ⚠ THREE OTHER C PROGRAMS COMPILE TO THIS EXACT MODULE AND ARE THEREFORE THE
; SAME FIXTURE, NOT ADDITIONAL COVERAGE (measured 2026-09-04, `-O1`, slice-body
; diff; PRD §14.3 rows A-4 / A-24 / A-25):
;
;   A-4   `int r; if (q == 5) r = cq_theta(0,.9); else r = 0;`  — SimplifyCFG
;         collapses the if/else to this diamond (only the `; preds =` COMMENT
;         order differs). This is the C spelling users write.
;   A-24  `if (q == 5) r = cq_theta(q - 5, .9);`  — the DERIVED-TEMP fold: `-O1`
;         value-propagates `q == 5` into the arm and const-folds `q - 5` to `0`,
;         deleting the `sub`. Byte-identical slice body. §14.2c records this as a
;         documented ACCEPT (seed 0 != the compare literal 5, so F2 is silent)
;         and §14.11 Q3 CORRECTED records why no cheap fence can separate the
;         two: there is no `f` left to inspect.
;   A-25  `if (q == 5) r = cq_theta(q * 0, .9);`  — the UNCONDITIONAL identity
;         fold. Byte-identical, and exactly faithful (`q*0` is |0> for every q).
;
; Committing three more .ll files with identical IR would be a false claim of
; coverage (the DER lesson), so they are recorded here instead.
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
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; THE WHOLE EMITTED STREAM, AS AN ADJACENCY CHAIN (`CHECK-NEXT` throughout, the
; Inc-3 F-L6-1 discipline: a loose `CHECK`-only form lets an injected gate pass).
; The ALLOC LANDS AFTER THE FLAG MINT — `lowerRotations` sets its insert point at
; the (hoisted) theta and the emitter put the theta there (PRD §14.1, a fixed
; design decision: hoisting the alloc higher is also correct physics but moves
; the golden).
;
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the PREPPED rail: minted with the SEED, then rotated under the flag
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the merge users read the PREPPED HANDLE (merge φ RAUW'd to T = M-β)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

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
