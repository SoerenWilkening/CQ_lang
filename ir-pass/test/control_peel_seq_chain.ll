; control_peel_seq_chain.ll — ACCEPT (bd test_C_libtooling-b6ap): **SCOPE H-1, THE
; BLOCK-LIFETIME HAZARD.** TWO SEQUENTIAL fused regions (the bd `hcrg` chain):
; region 1's merge `%m1` holds the peeled select AND hosts region 2's tainted
; branch, and region 1's flatten SPLICES `%m1` INTO `%entry` AND ERASES IT. Region
; 2's merge is fused too, so a second select is peeled into `%m2`.
;
; RED-GREEN: on `main` 0c7380c this declines `NESTED control flow under quantum
; control` — not the plain `control flow`, because with >1 phi `recoverRegion`
; falls past all three recognizers to its `hasTaintedCondBranch` test and `%m1`
; (the merge) does host a tainted branch.
;
; ⚠ WHAT THIS PINS. A `SelectRegion` contributes NO doomed block to
; `lowerControlRegions`' hcrg precedence graph (`doomedBlocks` names only
; Arm/ArmFalse/MergeBB, and a select erases only itself and its dead compare), so
; it generates no alias edge in either direction — but the BRANCH region DOES erase
; `MergeBB`, which is where the peeled select lives. The stream below shows the
; splice carrying the select and its compare clone into `%entry` with the rest of
; `%m1`'s body, in SOURCE ORDER: region 1, region 1's mux, region 2, region 2's
; mux, four flag mint/strip/free triples, every flag freed. The silent failure mode
; this rules out is a select spliced into the WRONG block and therefore reading a
; different basis; the loud one is a dangling use or a SIGSEGV.;
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
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

define i32 @example() {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  br i1 %c1, label %m1, label %a1
a1:
  %t1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m1
m1:
  %b1 = phi i32 [ %t1, %a1 ], [ 0, %entry ]
  %amux = phi i32 [ 5, %a1 ], [ 2, %entry ]
  %c2 = icmp eq i32 %b1, 1
  br i1 %c2, label %m2, label %a2
a2:
  %t2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 9.000000e-01)
  br label %m2
m2:
  %b2 = phi i32 [ %t2, %a2 ], [ 0, %m1 ]
  %dmux = phi i32 [ 7, %a2 ], [ 3, %m1 ]
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b0)
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %x2 = tail call i32 @cq_measure_si32(i32 noundef %b2)
  %xa = tail call i32 @cq_measure_si32(i32 noundef %amux)
  %xd = tail call i32 @cq_measure_si32(i32 noundef %dmux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  %s3 = add nsw i32 %s2, %xa
  %s4 = add nsw i32 %s3, %xd
  ret i32 %s4
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[HCMP9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP9]])
; CHECK-NEXT: %[[H10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP9]], i32 %[[H10]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP9]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP9]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP9]])
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
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H10]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: %[[H11:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP]], i32 %[[H11]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H10]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H10]], i32 1)
; CHECK-NEXT: %[[OUT6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP5]], i32 %[[SELOP7]], i32 %[[OUT6]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP5]])
; CHECK-NEXT: %[[SELOP8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP5]], i32 %[[SELOP8]], i32 %[[OUT6]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP5]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP5]], i32 %[[H10]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP5]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M12:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H10]])
; CHECK-NEXT: %[[M13:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H11]])
; CHECK-NEXT: %[[M14:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[M15:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT6]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M12]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M13]]
; CHECK-NEXT: %[[S3:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S2]], %[[M14]]
; CHECK-NEXT: %[[S4:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S3]], %[[M15]]
; CHECK-NEXT: ret i32 %[[S4]]


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
; XCNT-COUNT-8: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-9: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-5: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-5: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
