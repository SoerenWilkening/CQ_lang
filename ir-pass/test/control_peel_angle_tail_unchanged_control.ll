; control_peel_angle_tail_unchanged_control.ll — ACCEPT CONTROL, GREEN ON BOTH
; BINARIES (bd test_C_libtooling-b6ap, the >=2-phi CONTAINMENT GATE): the module of
; the shipped accept `control_phase_kickback_negated_tail_phi.ll` — a phase region
; whose merge holds `classifyPhaseKickback`'s optional ANGLE-TAIL phi, and NOTHING
; ELSE.
;
; ⚠ THIS IS THE CONCRETE REASON THE PEEL REFUSES A ONE-PHI MERGE (SCOPE OQ-5) — AND
; THE REASON IS "THE STAGE CANNOT TELL WHICH PHI IS THE REGION'S", NOT A
; WIRE-CROSSING. The sole phi here is a rotation ANGLE, its two incomings are
; distinct `double` CONSTANTS, `double` is muxable and it has a use — i.e. it passes
; P2/P3/P5/P6/P8 and would be PEELED by any predicate relaxed to ">=1 phi". On a
; merge with ONE phi the stage has no way to distinguish this phi (the region's own
; optional angle tail, whose lowering is a SHIPPED Rule-13-cleared kickback) from a
; genuinely independent mux, so relaxing the gate would replace that shipped
; lowering with a select on a fixture nothing would have flagged.
;
; ⚠ CORRECTED 2026-09-11 by the Rule-13 round-1 review (finding D1-DOC): the
; earlier wording here cited CLAUDE.md's f64/angle miscompile family ("a
; floating-point merge phi is an ANGLE, not data — do not cross these wires"; (wording retired from CLAUDE.md R3 on 2026-10-08: fp merge values can carry data; angle use is decided at rotation consumers)) as the
; reason. That framing is NOT what the measurement shows. The reviewer ran the
; one-phi module (`d01_tail_onephi.c`) against its two-phi sibling
; (`d02_tail_twophi.c`, where the SAME angle phi sits beside a data mux so the peel
; DOES fire) and the two emit the SAME UNITARY — relative phase `c=1 -> 2.2`,
; `c=0 -> 0.1` in both, with no `cqrt_alloc_f64` anywhere in either: the peeled
; angle is claimed by `classifyAngleSelect`'s Rz stem, which is an ANGLE consumer,
; so no wire is crossed. Peeling an angle-tail phi is not itself a hazard; peeling
; the WRONG phi is. Keep the gate, keep the fixture, drop the wire-crossing claim.
;
; The `>= 2` gate refuses it, `phaseAngleTail` still sees its one phi, and the
; emitted stream below is BYTE-IDENTICAL to the oracle's. The two-phi sibling is
; `control_peel_angle_tail_datamux.ll`.
;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

@off = global i32 3, align 4
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare void @cq_phi(double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr
declare double @cq_measure_f64(double noundef) local_unnamed_addr

define i32 @example() local_unnamed_addr {
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
  tail call void @cq_phi(double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %m
}
define i32 @main() local_unnamed_addr { %r = call i32 @example() ret i32 0 }

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[O:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[O]])
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 9.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 1.100000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[HCMP]], double 3.000000e-01), !cq.branchphase !0
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M1]]


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
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-1: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-2: _unc(
; UCNT-NOT:     _unc(
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-COUNT-3: call void @cqrt_rz_
; RZCNT-NOT:     call void @cqrt_rz_
