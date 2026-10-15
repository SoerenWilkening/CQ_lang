; control_peel_stateprep_datamux.ll — ACCEPT (bd test_C_libtooling-b6ap): THE
; FLAGSHIP. The owner's `example/grover/grover_oracle_uncompute.c` with `int b0`
; / `int b1`, as `clang -O1` hands it over (probe `p09_owner_int`): the classical
; guard `a >= 3` is proven equivalent to `b0 == 1`, the two source regions FUSE,
; and the merge holds the `b1` STATE-PREP phi (arm-defined — the region's own) and
; the `a` DATA MUX phi `[5, %arm], [2, %entry]` (both incomings constants).
;
; RED-GREEN: on `main` 0c7380c this module declines `control flow under quantum
; control`, anchored at the `br` (`CQ_CTRL_DBG=1`). Nothing about the region or
; the arm changed — only the second phi is gone.
;
; ⚠ ITS BYTE-IDENTITY PARTNER IS `control_peel_stateprep_datamux_peeled_control.ll`
; — the SAME module with the mux already spelled as a select + its own compare
; clone, which ACCEPTS on `main` today. The last RUN line lowers BOTH and `diff`s
; them: that is the increment's definition ("produce the module the hand peel
; already is") asserted rather than implied, and it is the only witness available
; because `-O1` destroys the peeled C spelling.
;
; THE CLONE, NOT A SHARE (SCOPE §6, MEASURED): a peeled select that REUSES the
; region's compare VALUE declines `condition data use neither escaped nor
; measured` — `classifyArms` sees a non-`BranchInst` user of the condition and
; `condDataUseDisposition` does not recognize a `SelectInst`, so it ends at its
; `Unowned` catch-all (probes `h09a`/`h09b`). With its own clone the region and
; the select each mint, strip and free their own flag on the same wire — the two
; `cq_template_icmp_eq_i32_hl` / `_unc` / `cqrt_free` triples below, which is
; exactly the shipped hcrg sequential-regions shape.;
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
; ---- THE BYTE-IDENTITY WITNESS (SCOPE §11.1). Lower the ALREADY-PEELED twin
; and diff the two modules; only the two path-bearing header lines are stripped.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_peel_stateprep_datamux_peeled_control.ll | sed -e '/^; ModuleID/d' -e '/^source_filename/d' > %t.peeled.ll
; RUN: sed -e '/^; ModuleID/d' -e '/^source_filename/d' %t.cqd0.ll > %t.fused.ll
; RUN: diff -u %t.fused.ll %t.peeled.ll
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
  %amux = phi i32 [ 5, %arm ], [ 2, %entry ]
  %b1 = phi i32 [ %t1, %arm ], [ 0, %entry ]
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %ma = call i32 @cq_measure_si32(i32 %amux)
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
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP1]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP1]], i32 %[[OUT]], i32 5)
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
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-3: _unc(
; UCNT-NOT:     _unc(
; (dm7f.81 R11 C-F1: CPCNT counts emitted copy CALLS only; an unused copy declaration is no longer minted. Measured.)
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
