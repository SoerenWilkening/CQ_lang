; control_peel_stateprep_datamux_peeled_control.ll — ACCEPT CONTROL (bd
; test_C_libtooling-b6ap): the flagship fixture's BYTE-IDENTITY PARTNER — the same
; program with the `a` mux ALREADY spelled as a `select` on its own compare clone,
; i.e. EXACTLY what `peelIndependentMergePhis` produces from
; `control_peel_stateprep_datamux.ll`.
;
; ⚠ THIS FIXTURE IS GREEN ON `main` 0c7380c TOO, and that is the point: it pins
; that the peel adds NO lowering — the 4.4 merge, the drbq Inc-4 state-prep arm
; and the flag discipline below are all pre-existing, and the increment is a
; RESTORATION of a spelling `-O1` destroys (`SCOPE_b6ap.md` §0.1) rather than a
; new emitter. If this file's stream ever moves, the peel's whole containment
; argument moves with it.
;
; The two files assert the SAME CHECK stream, and the fused one additionally
; `diff`s the two lowered modules.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL. `clang -O1` fuses two
; consecutive source `if`s whose conditions it proves equivalent into ONE diamond
; whose merge holds SEVERAL phi. `ControlRegion::Merge` is a single `PHINode *`,
; so `ControlDetect::soleMergePhi` returns null on >1 phi and `recoverRegion`
; declines `control flow` for a BOOKKEEPING reason, not a semantic one.
; `peelIndependentMergePhis` (`MergePhiPeel.cpp`) turns every merge phi the region
; does NOT define into a tainted-condition `select` on a CLONE of the region's
; compare, leaving the one phi the region needs and handing the mux to the 4.4
; `SelectClassify`/`SelectMergeEmit` substrate. The peel emits NO gate and NO
; runtime symbol; every gate checked below is the pre-existing substrate's.
;
; ⚠ THERE IS NO PLAIN-C TWIN, MEASURED (`SCOPE_b6ap.md` §0.1): writing the mux as
; a C ternary before OR after the region gives a stage-1 module BYTE-IDENTICAL to
; the fused one, because `-O1` turns a select on the dominating branch's condition
; in a 2-pred merge straight back into a phi. So this family is HAND IR by
; necessity, and the byte-identity witness is the fixture PAIR below.

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

define i32 @example() {
entry:
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm

arm:                                              ; preds = %entry
  %t1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %b1 = phi i32 [ %t1, %arm ], [ 0, %entry ]
  %cq.peel.cond = icmp eq i32 %b0, 1
  %cq.peel.mux = select i1 %cq.peel.cond, i32 2, i32 5
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %ma = call i32 @cq_measure_si32(i32 %cq.peel.mux)
  %s1 = add nsw i32 %m0, %m1
  %s2 = add nsw i32 %s1, %ma
  ret i32 %s2
}

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP]], i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: %[[SELOP2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[SELOP2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H3]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M4]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M5]]
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
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
