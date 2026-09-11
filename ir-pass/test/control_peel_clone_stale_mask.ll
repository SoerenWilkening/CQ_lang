; control_peel_clone_stale_mask.ll — ACCEPT (bd test_C_libtooling-b6ap, Rule-13
; ROUND-1 finding F-B6-1), and the ONE fixture that pins
; `replanReseedSpecialization` inside `adjudicateTaintDelta`.
;
; ⚠ THE SHAPE THE ESCAPE NET CANNOT SAVE, found while building the F-B6-1 fix and
; NOT among the reviewer's five. `@helper(q, m)` has a ROUND-1 TAINTED argument, so
; the site is ALREADY a proven Phase-6 candidate in `plan6.Pending` with the frozen
; mask {Q,C} — and a site in `Pending` is CARVED by `declineTaintEscapes`
; (`shouldSpecialize`). Re-running the escape net over the peel's taint delta
; therefore changes NOTHING here: the peel makes `%8` quantum, the mask stays {Q,C},
; and the step-262 driver clones a body that reads the 4.4 merge OUT-RAIL as an
; `_hl` CLASSICAL LITERAL — `cq_template_add_i32_hl(%h1, 4)`, i.e. the rail's
; runtime HANDLE TAG added to a qubit register. That is the bd `afmv` verify-clean
; wrong unitary, and it is why the fix had to be the WHOLE four-call sequence
; `repropagateControlMerges` runs and not the escape net alone.
;
; MUTANT M-A (the pin): delete `replanReseedSpecialization` from
; `adjudicateTaintDelta`, rebuild, and this fixture emits
; `cq_template_add_i32_hl(i32 %h1, i32 4)` at `opt` exit 0 — MEASURED. With the call
; in place the clone is the bare Q+Q twin `cq_template_add_i32(%out, %h3)` checked
; below. NOTE the mutant is invisible to `..._clone_measured.ll` (whose site is a
; round-2 DETECTION, not a re-plan) and to every escape fixture: two calls, two
; different pinning probes.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): an
; accept-only normalisation that turns each merge phi a tainted control region does
; NOT define into a tainted-condition `select` on a CLONE of the region's compare.
; It emits no gate and no runtime symbol; every gate checked here is the
; pre-existing substrate's.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SPEC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOHL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
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
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = phi i32 [ 7, %4 ], [ 5, %0 ]
  %9 = tail call fastcc i32 @helper(i32 noundef %7, i32 noundef %8)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

define internal fastcc i32 @helper(i32 noundef %0, i32 noundef %1) unnamed_addr {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

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
; CHECK-NEXT: %[[S7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S7]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: %[[S5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S5]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_helper_11(i32 noundef %[[HA]], i32 noundef %[[OUT]])

; The RE-PLANNED clone: BOTH parameters are quantum handles, so the `add` is the
; bare Q+Q template and its `_unc` twin — never the `_hl` literal form.
; SPEC: define internal fastcc i32 @__cq_q_helper_11(i32 noundef %[[P0:[a-zA-Z0-9_.]+]], i32 noundef %[[P1:[a-zA-Z0-9_.]+]])
; SPEC-NEXT: %[[HOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[P1]], i32 %[[P0]])
; SPEC-NEXT: %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; SPEC-NEXT: call void @cqrt_copy_i32(i32 %[[HOP]], i32 %[[CO]])
; SPEC-NEXT: call void @cq_template_add_i32_unc(i32 %[[HOP]], i32 %[[P1]], i32 %[[P0]])
; SPEC-NEXT: call void @cqrt_free(i32 %[[HOP]])
; SPEC-NEXT: ret i32 %[[CO]]

; ---- THE MUTANT'S OWN NEGATIVE: the stale-mask clone emits `add_i32_hl`. This is
; the single line that goes from absent to present under M-A.
; NOHL-NOT: cq_template_add_i32_hl

; ---- Whole-file negatives, each in its OWN pure-negative prefix.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; NOROUTE-NOT: call void @cqrt_rz_
; ---- Whole-file EXACT COUNTS (declares included).
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-5: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-5: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
