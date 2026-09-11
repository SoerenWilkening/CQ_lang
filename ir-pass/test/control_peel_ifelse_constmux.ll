; control_peel_ifelse_constmux.ll — ACCEPT (bd test_C_libtooling-b6ap): the
; IF/ELSE orientation (SCOPE §4). The merge's two predecessors are BOTH arms, so
; there is no `Pred` edge; P3 still demands both incomings dominate the `br`, which
; for an if/else means neither is arm-defined — the phi was a cross-arm mux of
; pred-available values. Here BOTH phis peel, the merge ends EMPTY, and the region
; is claimed by `classifyPhaseKickback` (which asks `hasNPredecessors(2)`, not for
; a phi) — the two `cqrt_rz_i1` below, one per arm, the second `cqrt_x`-bracketed
; for the ¬flag arm.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; ⚠ HAND IR BY NECESSITY: `clang -O1` folds a cross-arm constant mux away entirely.
; The orientation is kept in the predicate and fixtured rather than special-cased.
;
; POLARITY (Rule 9) is read off the branch, never assumed: `TruePred` is the TRUE
; successor's arm block, so `%amux = phi [2, %armt], [5, %armf]` becomes
; `select C, 2, 5` and the emitted copies put 2 under the un-bracketed flag.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): an
; accept-only normalisation that turns each merge phi a tainted control region does
; NOT define into a tainted-condition `select` on a CLONE of the region's compare,
; so `ControlDetect::soleMergePhi` sees the ONE phi it requires. It emits no gate
; and no runtime symbol; every gate checked here is the pre-existing substrate's.
; See `control_peel_stateprep_datamux.ll` for the full account and the
; byte-identity pair.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %armt, label %armf
armt:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
armf:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %amux = phi i32 [ 2, %armt ], [ 5, %armf ]
  %bmux = phi i32 [ 11, %armt ], [ 13, %armf ]
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %ma = call i32 @cq_measure_si32(i32 %amux)
  %mb = call i32 @cq_measure_si32(i32 %bmux)
  %s1 = add nsw i32 %m0, %ma
  %s2 = add nsw i32 %s1, %mb
  ret i32 %s2
}

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 0x3FE6666666666666), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 3.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP3]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: %[[SELOP4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP3]], i32 %[[SELOP4]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP3]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP3]])
; CHECK-NEXT: %[[HCMP5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 11)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP5]], i32 %[[SELOP7]], i32 %[[OUT6]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP5]])
; CHECK-NEXT: %[[SELOP8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 13)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP5]], i32 %[[SELOP8]], i32 %[[OUT6]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP5]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP5]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP5]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[M10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT6]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M9]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M10]]
; CHECK-NEXT: ret i32 %[[S2]]


; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the drbq Inc-4 F-L6-1 lesson).
; The peel emits NOTHING itself: every gate below is the pre-existing substrate's.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; ---- Whole-file EXACT COUNTS. An injected extra `cqrt_x` / `cqrt_free` /
; controlled copy, or a DROPPED `_unc` strip, changes one of these even when
; it slots into a position the ordered stream above still matches.
; XCNT-COUNT-6: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-7: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-4: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-5: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-COUNT-2: call void @cqrt_rz_
; RZCNT-NOT:     call void @cqrt_rz_
