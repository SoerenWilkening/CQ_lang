; control_peel_freeze_incoming.ll — ACCEPT (bd test_C_libtooling-b6ap, Rule-13
; ROUND-1 review, the P3b DOC item): a `freeze i32 poison` incoming IS PEELED, and
; that is correct rather than a gap in the `isa<UndefValue>` refusal next door.
;
; P3b refuses a LITERAL `undef`/`poison` incoming because the peel would put it into
; a `select` arm and thence into TWO emitted gate slots (the controlled copy and its
; `_unc`), where at the `-O0` stage-3 link the two slots may read as two DIFFERENT
; values, so the adjoint stops inverting its forward (Rules 6, 8) — the population
; `LiteralIntegrity`'s guard 1 counts. A `freeze` is an `Instruction`, not an
; `UndefValue`, so it falls through to P3's dominance clause and peels.
;
; ⚠ AND THE ARGUMENT IS THE PROPERTY, NOT THE TYPE TEST: `freeze` is SINGLE-VALUED
; BY DEFINITION — every read of one `freeze` yields the same bit pattern — which is
; exactly what guard 1 is counting. It cannot exhibit the two-slots-two-values
; hazard, so refusing it would be an over-decline with no argument behind it. Below,
; the one `freeze` survives verbatim and feeds `cqrt_alloc_i32(i32 %frz)`: ONE
; runtime value, read once.
;
; THE PAIR: `control_peel_reject_poison_incoming.ll` is the same module with the
; `freeze` deleted and `poison` named directly in the phi — `control flow`, NOT
; peeled. One token apart, opposite dispositions. (`control_peel_reject_undef_incoming.ll`
; is the `undef` spelling of that same refusal.)
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): an
; accept-only normalisation that turns each merge phi a tainted control region does
; NOT define into a tainted-condition `select` on a CLONE of the region's compare.
; It emits no gate and no runtime symbol; every gate checked here is the
; pre-existing substrate's.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FRZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %frz = freeze i32 poison
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 5, %3 ], [ %frz, %0 ]
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; POLARITY (Rule 9): the ARM is the FALSE successor, so `TruePred` is `Pred` itself
; and the `freeze` sits in the SELECT's TRUE slot — its copy is the un-bracketed
; one, and the constant 5 is the `cqrt_x`-bracketed one.
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[FRZ:[a-zA-Z0-9_.]+]] = freeze i32 poison
; CHECK-NEXT: %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT: %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F0]], i32 %[[HA]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[FRZ]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[SF]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: %[[S5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S5]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])

; ---- Whole-file negatives, each in its OWN pure-negative prefix.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; NOROUTE-NOT: call void @cqrt_rz_
; ---- EXACTLY ONE `freeze`, i.e. the literal reaches ONE gate slot. Two would be
; the `LiteralIntegrity` guard-1 population this clause is about.
; FRZCNT-COUNT-1: = freeze i32 poison
; FRZCNT-NOT:     = freeze
; ---- Whole-file EXACT COUNTS (declares included).
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-3: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-3: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
