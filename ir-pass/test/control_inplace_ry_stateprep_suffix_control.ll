; control_inplace_ry_stateprep_suffix_control.ll — ACCEPT. The ONE-TOKEN CONTROL
; for `control_inplace_ry_reject_stateprep_unrecognized_suffix.ll`.
;
; Byte-identical to that file except the arm's callee is `@cq_theta_si32`
; instead of `@cq_theta_si32x`. Both declarations are present in BOTH files, so
; the only difference is which one the arm calls — which makes F1's third
; sub-clause the whole discriminator (round-1 Rule-13 review, lens L1 F-L1-1).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32x(i32, double)
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
  ret i32 %mr
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl({{.*}}, i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)

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
; ⚠ ADDED 2026-09-05 (round-2 Rule-13 review, lens R2 finding F-R2-1, WEAK-PIN).
; THIS WAS THE ONE ACCEPT OF 28 THAT COULD NOT SEE A STANDING `@cq_theta` CALL —
; measured by injecting `%injtheta = call i32 @cq_theta_si32(i32 0, double 1.0)`
; before the first `ret` of every accept's lowered module: caught by 27 of 28,
; MISSED here, in every prefix. Its 26 siblings carry the whole-file
; `; NOROUTE-NOT: cq_theta`; this file dropped it SILENTLY, because the fixture
; deliberately declares BOTH suffixes and the bare-name NOT would match the
; surviving `declare i32 @cq_theta_si32x(i32, double)` line.
; THE REASON IT MATTERS MORE HERE THAN ANYWHERE: this file is the ACCEPT TWIN of
; `..._reject_stateprep_unrecognized_suffix.ll`, whose entire counterfactual is
; "with F1's clause 3 disabled the module ACCEPTS with a STANDING
; `@cq_theta_si32x` inside a flag mint/strip/free" — i.e. the fixture whose
; subject is a residual intrinsic was the only one blind to a residual intrinsic.
; Narrowed to a CALL, which the `declare` line does not contain. VALIDATED BOTH
; WAYS: FileCheck exit 1 on the injected module, exit 0 on the clean one. Do not
; drop it again; if a future edit needs the declare, narrow further, never delete.
; NOROUTE-NOT: call i32 @cq_theta
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
