; control_peel_fp_datamux_phase.ll — ACCEPT (bd test_C_libtooling-b6ap): the peeled
; phi is a REAL `double` DATA MUX and the arm is a register-free `cq_phi` PHASE.
; Both phis are handled: the fp mux peels to a select claimed by the kjd1 fp family
; (`cqrt_copy_f64_controlled`), and the merge is then EMPTY, so
; `classifyPhaseKickback` claims the region and emits the bracketed `cqrt_rz_i1`.
; Probe `p87_fp_mux` + a phase arm / hand peel `h87c`.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; ⚠ AN fp MERGE PHI IS DATA *OR* AN ANGLE AND THE TWO MUST NEVER BE CROSSED
; (CLAUDE.md's named f64/angle miscompile family). The peel does NOT decide which:
; it hands the substrate a `select`, and `SelectClassify`'s gate 3 partitions it —
; a select whose consumer is a rotation's ANGLE slot goes to `classifyAngleSelect`,
; anything else to the kjd1 fp DATA merge. Here the consumer is `cq_measure_f64`,
; so it is DATA and a real f64 rail is correct. The angle half of that partition is
; pinned by `control_peel_angle_tail_datamux.ll`, where the SAME peel feeds a
; `cq_phi` angle slot and NO fp rail is minted at all.
;
; ⚠ THE fp MUX BESIDE A STATE-PREP ARM (rather than a phase arm) is an
; OVER-DECLINE — see `control_peel_reject_fp_stateprep.ll` (SCOPE H-3 / OQ-2). The
; arm class is what separates the two, which is why both are committed.;
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
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %d0 = call double @cq_theta_f64(double 0.000000e+00, double 3.000000e-01)
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  %d1 = fadd double %d0, 2.500000e+00
  br i1 %c, label %merge, label %arm
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %dmux = phi double [ %d0, %arm ], [ %d1, %entry ]
  %imux = phi i32 [ 5, %arm ], [ 2, %entry ]
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %md = call double @cq_measure_f64(double %dmux)
  %mi = call i32 @cq_measure_si32(i32 %imux)
  %di = fptosi double %md to i32
  %s1 = add nsw i32 %m0, %di
  %s2 = add nsw i32 %s1, %mi
  ret i32 %s2
}

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[H7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H7]], double 5.000000e-01)
; CHECK-NEXT: %[[HOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[H]], double 2.500000e+00)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H7]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 0x3FE6666666666666), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H7]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H7]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[HCMP3]], i32 %[[HOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[HCMP3]], i32 %[[H]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP3]], i32 %[[H7]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP3]])
; CHECK-NEXT: %[[HCMP4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H7]], i32 1)
; CHECK-NEXT: %[[OUT5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT5]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT5]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP4]], i32 %[[H7]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP4]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H7]])
; CHECK-NEXT: %[[M8:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[OUT]])
; CHECK-NEXT: %[[M9:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT5]])
; CHECK-NEXT: %[[DI:[a-zA-Z0-9_.]+]] = fptosi double %[[M8]] to i32
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[DI]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M9]]
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
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-4: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-4: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-COUNT-1: call void @cqrt_rz_
; RZCNT-NOT:     call void @cqrt_rz_
