; control_inplace_ry_stateprep_i8.ll — ACCEPT: controlled STATE PREP at the i8
; width (PRD §14.3 rows A-5..A-8, the WIDTH axis; bd test_C_libtooling-drbq
; Inc 4).
;
; ⚠ HEADER CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L4 finding
; F-L4-2). This paragraph used to claim the fixture pins F1's THIRD sub-clause
; (the seed's LLVM type vs `typeForAbiWidth(abiWidthFor(callee name))`). IT DOES
; NOT: delete that clause outright and this file stays GREEN, because the seed's
; type already EQUALS the name-derived width's type on every input it presents,
; so the clause is a no-op here. Its real pin is
; `control_inplace_ry_reject_stateprep_unrecognized_suffix.ll` (an UNRECOGNIZED
; suffix, where `abiWidthFor` is empty), with the accept twin
; `..._stateprep_suffix_control.ll`.
;
; The second stale claim was "before Inc 4 those two were never cross-checked at
; all". The cross-check has lived in `TaintPropagation::declMatchesPrototype`
; since long before Inc 4 (`FT->getParamType(0) == wd.llvmTypeFor(sfx)`), and it
; declines `cq rotation lowering: unsupported declared prototype for
; cq_theta_f64` on the PRD's own `fp128` module — on BOTH binaries, measured.
;
; WHAT THIS FIXTURE ACTUALLY PINS, and it is real: `lowerRotations` derives BOTH
; the alloc symbol `cqrt_alloc_i8` and the gate symbol
; `cqrt_ry_i8_controlled` from the CALLEE NAME (`cq_theta_si8` → `i8`),
; and the alloc lands at the theta's HOISTED position — after the flag mint,
; before the strip — at this width.
;
; `i8` is in `abiWidthHasControlledRotation`'s nine, checked in DETECTION (a
; decline inside `lowerRotations` would be a decline after the emitter had
; already hoisted the theta and `RegionFlatten` erased the diamond — Rule 9).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)

define i32 @example(i8 %u0) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  %c = icmp eq i8 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i8 @cq_theta_si8(i8 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i8 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i8 @cq_measure_si8(i8 %q)
  %mr = call i8 @cq_measure_si8(i8 %rm)
  ret i32 0
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0)
; CHECK-NEXT: call void @cqrt_ry_i8(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i8_hl(i32 %[[Q]], i8 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK-NEXT: call void @cqrt_ry_i8_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i8_hl_unc(i32 %[[F]], i32 %[[Q]], i8 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

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
; NOROUTE-NOT: call void @cqrt_ry_i8(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
