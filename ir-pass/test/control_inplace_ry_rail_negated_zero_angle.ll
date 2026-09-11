; control_inplace_ry_rail_negated_zero_angle.ll — ACCEPT: a NEGATED rail arm
; whose angle is exactly `0.0`. THE FINITE BOUNDARY OF ROUND-1 RULE-13 FINDING
; F-1's fence (bd `test_C_libtooling-l4x4`, sub-increment l4x4.b).
;
; WHY THIS FILE EXISTS. F-1 added one conjunct — a non-finite CONSTANT angle on
; the negated form declines (`..._reject_rail_negated_{inf,nan,neginf}_angle.ll`)
; — and a fence with no accept beside it is a fence nobody can tell from a
; blanket refusal. `0.0` is the value most likely to be swept up by a careless
; re-spelling of "is this angle usable" (`isNonZero`, `isNormal`, a truthiness
; test), and it is PERFECTLY FINE: `Ry(0)·Ry(−0) = I` EXACTLY — `−0.0` and `0.0`
; both give `cos(0) = 1` and `sin(±0) = ±0`, so each of the W tensored qubits
; sees the identity with no rounding anywhere. Deleting the `isFinite()` question
; and refusing every constant would redden exactly this file and its run-time
; sibling.
;
; NOTE THE ANGLE PAIR IN THE ASSERTIONS: the source's `0.0` is emitted verbatim
; on the unconditional gate and `−0.0` on the controlled one. That IS the sign
; flip (`APFloat::changeSign`), and it is the reason the whole negated form is
; exact where Inc-2b's by-difference form needs `kAngleSelectMaxRoundingRad`:
; `fneg` is a single sign bit, never an `fsub`.
;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate. GREEN on the
; l4x4.b checkpoint 267937d and after the F-1 fix — the conjunct is a NARROWING
; and this file is the measurement that it narrowed nothing it should not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 0.000000e+00)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double -0.000000e+00)
;
; ---------------------------------------------------------------------------
; Whole-file PURE negatives (the Inc-3 F-L6-1 / Inc-4 F-L7-1 lesson: a POSITIVE
; directive inside a prefix WINDOWS every negative one of that prefix, so each
; count gets its own CNT prefix). `NOX` is the non-negotiable — bd `3qlq.4`'s
; "never a `cqrt_x` on a user register".
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
