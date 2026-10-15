; control_peel_clone_measured.ll — ACCEPT (bd test_C_libtooling-b6ap, Rule-13
; ROUND-1 finding F-B6-1): the peeled mux is passed to a VISIBLE-BODY classical
; callee whose result is then MEASURED, and the Phase-6 clone-on-taint machinery
; specializes it. Probe `r20_clone_measured.c`, plain C at `-O1`.
;
; ⚠ THIS FIXTURE WAS THE REVIEW'S DECISIVE PAIR, AND IT IS AN ACCEPT ON PURPOSE.
; At the hand-back tree the peel made `%7` quantum ~90 lines after
; `detectSpecializations` had run, so `@helper` was NEVER specialized: the emitted
; module called the UNTOUCHED CLASSICAL BODY with the quantum rail HANDLE and then
; measured `handle+1`, an UNRELATED register (21 trace lines,
; `cqrt_measure_i32(h5)` where `h5` is `cqrt_alloc_i32(7)`), at `opt` exit 0,
; verify-clean and STRICT stage-2b `0 violation(s)`.
;
; The reviewer's hand-peeled twin of this very module (`r23_clone_handpeel.s1.ll`)
; lowers CORRECTLY on the ORACLE — 26 trace lines through `@__cq_q_helper_1` — so
; the increment's own contract ("produce the module the hand peel already is") says
; the right disposition here is ACCEPT-AND-CORRECT, not a decline. MEASURED after
; the fix: the SUBJECT's lowered IR for this module is BYTE-IDENTICAL to the
; ORACLE's for the hand-peeled twin, and the two runtime traces are byte-identical.
;
; WHICH RE-ASKED STAGE BUYS IT: `detectSpecializations(&delta)` (bd 9paa's round-2
; DETECTION mode), inside `adjudicateTaintDelta`. MUTANT M-B (the pin): delete that
; one call and this fixture goes RED with `cq taint escape: tainted value consumed
; by an unknown callee` — an OVER-decline, since the hand peel accepts. Measured.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): an
; accept-only normalisation that turns each merge phi a tainted control region does
; NOT define into a tainted-condition `select` on a CLONE of the region's compare,
; so `ControlDetect::soleMergePhi` sees the ONE phi it requires. It emits no gate
; and no runtime symbol; every gate checked here is the pre-existing substrate's.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SPEC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ 7, %4 ], [ 5, %0 ]
  %8 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %9 = tail call fastcc i32 @helper(i32 noundef %7)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

define internal fastcc i32 @helper(i32 noundef %0) unnamed_addr {
  %2 = add nuw nsw i32 %0, 1
  ret i32 %2
}

; The region's own phi `%8` stays and the arm's theta becomes the in-place
; controlled Ry; the INDEPENDENT phi `%7` is peeled into the 4.4 controlled-copy
; merge, and the merge OUT-RAIL is what reaches the specialized clone.
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HA]], double 4.000000e-01)
; CHECK-NEXT: %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F0]], i32 %[[HA]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_helper_1(i32 noundef %[[OUT]])
; CHECK-NEXT: %[[M0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[HA]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])

; The CLONE is the whole point of this fixture: a Bennett-wrapped quantum twin of
; `@helper` whose `add` is a REVERSIBLE TEMPLATE on the rail, copied out and
; uncomputed — not the untouched classical body reading the handle tag.
; SPEC: define internal fastcc i32 @__cq_q_helper_1(i32 noundef %[[A:[a-zA-Z0-9_.]+]])
; SPEC-NEXT: %[[HOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 1)
; SPEC-NEXT: %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; SPEC-NEXT: call void @cqrt_copy_i32(i32 %[[HOP]], i32 %[[CO]])
; SPEC-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[HOP]], i32 %[[A]], i32 1)
; SPEC-NEXT: call void @cqrt_free(i32 %[[HOP]])
; SPEC-NEXT: ret i32 %[[CO]]

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive line
; inside one WINDOWS every negative after it — the drbq Inc-4 F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; ---- Whole-file EXACT COUNTS (declares included — an injected extra gate, or a
; DROPPED `_unc` strip, moves one of these even when it slots into a position the
; ordered stream above still matches).
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-5: _unc(
; UCNT-NOT:     _unc(
; (dm7f.81 R11 C-F1: CPCNT counts emitted copy CALLS only; an unused copy declaration is no longer minted. Measured.)
; CPCNT-COUNT-1: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-NOT:     call void @cqrt_rz_
