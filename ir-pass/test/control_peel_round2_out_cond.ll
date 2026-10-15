; control_peel_round2_out_cond.ll — ACCEPT (bd test_C_libtooling-b6ap): **THE
; ROUND-2 PIN.** A 6.5 classical-call region, then a FUSED 2-phi diamond whose
; condition `icmp eq i32 %out, 13` reads THAT REGION'S MERGE PHI. At round 1 `%out`
; is CLASSICAL, so the second `br` is not a tainted branch at all and
; `detectControlRegions` never looks at it; `repropagateControlMerges` re-seeds
; taint from the 6.5 `%out` rail and runs a SECOND, FULL round of detection, and
; only THEN is the 2-phi wall reached. Probe `p80_round2_out_cond` / hand peel
; `h80`; its one-phi control `p81` already accepts on `main`, so the 2-phi wall is
; the only thing that was stopping it.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; ⚠ THIS FIXTURE GOES RED IF THE PEEL RUNS ONLY ONCE. It is the fixture form of
; CLAUDE.md's standing lesson "a stage that runs ONCE has a round-2-FALSE premise"
; (F-L3-1, F-R1-1, F-B1R2-1). `peelIndependentMergePhis` is called immediately
; before EVERY `detectControlRegions` call in the tree — `CQLoweringPass::run`, the
; second entry point, and INSIDE `detectAndLowerOnwardControl`'s round-2 fixpoint
; loop — and that uniform rule is grep-checkable on purpose.;
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %m2, label %arm2
arm2:
  %t2 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %m2
m2:
  %amux = phi i32 [ 5, %arm2 ], [ 2, %m1 ]
  %b1 = phi i32 [ %t2, %arm2 ], [ 0, %m1 ]
  %x0 = call i32 @cq_measure_si32(i32 %b0)
  %x1 = call i32 @cq_measure_si32(i32 %out)
  %x2 = call i32 @cq_measure_si32(i32 %b1)
  %xa = call i32 @cq_measure_si32(i32 %amux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  %s3 = add nsw i32 %s2, %xa
  ret i32 %s3
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @f(i32 4) #1
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP]], i32 %[[OUT1]], i32 %[[R]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OUT1]], i32 13)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: %[[H7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP3]], i32 %[[H7]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP3]], i32 %[[OUT1]], i32 13)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP3]])
; CHECK-NEXT: %[[HCMP4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OUT1]], i32 13)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP4]], i32 %[[OUT1]], i32 13)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP4]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT1]])
; CHECK-NEXT: %[[M9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H7]])
; CHECK-NEXT: %[[M10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M8]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M9]]
; CHECK-NEXT: %[[S3:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S2]], %[[M10]]
; CHECK-NEXT: ret i32 %[[S3]]


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
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-4: _unc(
; UCNT-NOT:     _unc(
; (dm7f.81 R11 C-F1: CPCNT counts emitted copy CALLS only; an unused copy declaration is no longer minted. Measured.)
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
