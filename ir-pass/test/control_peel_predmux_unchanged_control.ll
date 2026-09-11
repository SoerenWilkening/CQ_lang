; control_peel_predmux_unchanged_control.ll — ACCEPT CONTROL, GREEN ON BOTH
; BINARIES (bd test_C_libtooling-b6ap, SCOPE H-7 / §2 "not before PredMux"): a
; 2-phi merge whose arm is FULLY SPECULATABLE, so `flattenPredMuxRegions` claims
; the WHOLE region, erases the arm and the CFG, and lowers it as straight-line
; block-predicate selects. Probe `p30_chain_2phi` / `h30_both_armdefined`.
;
; ⚠ THE PEEL MUST NOT TOUCH IT, AND THE SLOT IS WHAT GUARANTEES THAT.
; `peelIndependentMergePhis` runs AFTER the PredMux fixpoint, so every region
; PredMux can claim is already gone before the peel looks. Running it EARLIER would
; hand PredMux a merge with one phi where it had two, and BOTH of PredMux's own W5
; and W7 witnesses require `NumMergePhis == 1` — an earlier peel could therefore
; silently MOVE a PredMux accept, which is a changed emitted stream with no
; diagnostic anywhere.
;
; This fixture is the local witness; the global one is the whole-corpus measurement
; (0 RCDIFF / 0 DIAGDIFF / 0 OUTDIFF over all 1776 pre-existing fixtures, oracle
; `main` 0c7380c vs subject). Note the lowered stream below has no `br i1` at all
; and the arm chain hoisted — that is PredMux's signature, not the peel's.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %2 = add nsw i32 %1, 1
  %3 = icmp eq i32 %1, 1
  %4 = select i1 %3, i32 7, i32 %2
  %5 = select i1 %3, i32 14, i32 0
  %6 = tail call i32 @cq_measure_si32(i32 noundef %1) 
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) 
  %8 = add nsw i32 %7, %6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %5) 
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[HOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP]], i32 %[[HOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 14)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[SELOP3]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: %[[SELOP4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[SELOP4]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M5]], %[[M]]
; CHECK-NEXT: %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT2]])
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[V1]], %[[M6]]
; CHECK-NEXT: ret i32 %[[V2]]


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
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-3: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-5: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
