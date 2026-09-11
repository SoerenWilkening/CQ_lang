; control_inplace_ry_rail_negated_runtime_angle.ll — ACCEPT: a NEGATED rail arm
; whose angle is a CLASSICAL RUN-TIME value (the `CreateFNeg` path).
;
; *** THIS FILE PINS A DECISION, NOT A CONVENIENCE. *** Round-1 Rule-13 finding
; F-1 (bd `test_C_libtooling-l4x4`, sub-increment l4x4.b) fenced a non-finite
; CONSTANT angle on this shape; the fix brief's decision (b) is that a RUN-TIME
; angle KEEPS ACCEPTING, and a decision recorded only in prose is one the next
; widening or narrowing will not see. If someone re-spells the F-1 conjunct as
; "the angle must be a finite `ConstantFP`" — i.e. imports Inc-2b's
; constant-arms-only narrowing — THIS FIXTURE GOES RED, which is the intended
; alarm: that narrowing would refuse every run-time angle on the negated form.
;
; WHY THE INC-2b F-11 STRUCTURE DOES NOT TRANSFER, in one line: Inc 2b refuses
; run-time arms because `fsub` MANUFACTURES a non-finite value FROM TWO FINITE
; ONES (measured there at `±8.98846567431158e307`), so its precondition is
; DISPROVEN on well-formed input. Here the emitter performs `fneg` — one sign
; bit — and `fneg` of a finite value is finite, so the identity `Ry(θ)·Ry(−θ) = I`
; can only fail on an angle that was ALREADY non-finite, which is an ill-formed
; CQ program in every spelling (`Ry(NaN)` lands on the taken branch of the
; compare twin too). The constant case is the one the compiler can SEE, and it
; declines. The residual — a run-time angle that is non-finite AT RUN TIME — and
; the owner option that removes it for every angle (the 1b-B.1 `CopyRailRoot`
; ancilla with the `cqrt_x` bracket ON THE ANCILLA, which fires exactly ONE
; rotation) are recorded at the clause in `ArmClassify.cpp` and in
; `FIX_l4x4b_R1.md`.
;
; THE `fneg` IS IN THE ASSERTIONS ON PURPOSE: it is the ONE instruction the
; emitter inserts between the two gates, it is CLASSICAL, and the round-1 review
; established (brief item 2) that nothing in the pipeline can place a GATE in
; that slot. Transcribed from plain C at `-O1`
; (`review_l4x4b_r1_probes/n11_neg_runtime_angle.c`, a `double` parameter).
;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4 (`bare i1 register
; condition`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FNEGCNT < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1, double %a) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double %a)
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
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double %a)
; CHECK-NEXT: %[[NEG:[a-zA-Z0-9_.]+]] = fneg double %a
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double %[[NEG]])
;
; ---------------------------------------------------------------------------
; Whole-file PURE negatives + exact counts, each in its own prefix.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOROUTE-NOT: fsub
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
; FNEGCNT-COUNT-1: fneg double
; FNEGCNT-NOT:     fneg double
