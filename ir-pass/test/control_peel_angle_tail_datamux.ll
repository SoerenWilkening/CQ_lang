; control_peel_angle_tail_datamux.ll — ACCEPT (bd test_C_libtooling-b6ap): the
; merge holds `classifyPhaseKickback`'s optional ANGLE-TAIL phi (a `double` muxed
; into a `cq_phi` in the merge block) BESIDE an int data mux. This is the shape the
; implementation round probed FIRST, because it is the one that could have crossed
; the f64/angle wires: `phaseAngleTail` refuses a second phi, so today the whole
; region declines `control flow`, and after the peel BOTH phis are selects.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; ⚠ THE MEASUREMENT THAT MATTERS: the peeled ANGLE select is claimed by
; `classifyAngleSelect`'s Rz stem and lowers to the KICKBACK PAIR
; (`cqrt_rz_i1(f, 0.30)` under the `cqrt_x` bracket, `cqrt_rz_i1(f, 0.11)` without)
; — NOT to the kjd1 fp data merge. There is NO `cqrt_alloc_f64` anywhere below and
; the NOROUTE prefix pins it: the angle is never materialised on a quantum f64
; rail, which is precisely the Rule-3 wire-crossing of PRD §1's F-L3-1. The peel
; does not decide data-vs-angle; `SelectClassify`'s gate 3 does, exactly as it does
; for a source-written select. Its DATA twin is
; `control_peel_fp_datamux_phase.ll`.
;
; ⚠ HAND IR BY NECESSITY — `clang -O1` never emits an angle phi beside a data phi
; in one merge (it sinks the common `cq_phi` call and produces an angle select
; directly, which is the drbq Inc-2b shape).
;
; The 1-phi ANGLE-TAIL region on its own is UNTOUCHED by the peel (>=2-phi
; containment gate) — `control_peel_angle_tail_unchanged_control.ll`.;
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

@off = internal global i32 0
define i32 @example() {
entry:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %q = add nsw i32 %o, %t
  %c = icmp eq i32 %q, 5
  br i1 %c, label %mrg, label %arm
arm:
  tail call void @cq_phi(double noundef 9.000000e-01)
  br label %mrg
mrg:
  %a = phi double [ 1.100000e-01, %entry ], [ 3.000000e-01, %arm ]
  %d = phi i32 [ 2, %entry ], [ 5, %arm ]
  tail call void @cq_phi(double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  %md = tail call i32 @cq_measure_si32(i32 noundef %d)
  %s = add nsw i32 %m, %md
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 9.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HCMP4]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP4]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP4]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP4]])
; CHECK-NEXT: %[[HCMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP3]], double 3.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP3]], double 1.100000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP3]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP3]])
; CHECK-NEXT: %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M6]], %[[M7]]
; CHECK-NEXT: ret i32 %[[S]]


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
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-4: _unc(
; UCNT-NOT:     _unc(
; (dm7f.81 R11 C-F1: CPCNT counts emitted copy CALLS only; an unused copy declaration is no longer minted. Measured.)
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-COUNT-3: call void @cqrt_rz_
; RZCNT-NOT:     call void @cqrt_rz_
