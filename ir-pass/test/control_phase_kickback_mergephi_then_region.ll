; control_phase_kickback_mergephi_then_region.ll — ACCEPT (bd `3qps`, Track P).
; THE F-M1 ORDERING PROBE, one consumer over. A SECOND control region follows the
; merge-φ kickback, so the bd `hcrg` precedence graph carries a CHAIN of three
; regions: prep → φ-kickback → compare-kickback.
;
; WHY THIS FILE EXISTS. Track M's round-1 finding F-M1 was that a `SelectRegion`
; is INERT in that graph (all four block fields null), so a FOLLOWING region could
; schedule the prep LAST and the select's condition re-read would find the φ still
; live. The fix there was `ControlRegion::PrepRegionIdxs` + one edge. A
; `PhaseKickback` is NOT inert — it has real block fields — so the graph already
; handles it, and this file is the pin that it does: each region's `Pred` is the
; previous one's `MergeBB`, so `sequentialChainAlias` gives
; `Precedes[later] = {earlier}` and Kahn emits LATEST-FIRST. Every emitter inserts
; POSITIONALLY, so the STREAM is source order regardless of the schedule — which
; is exactly what the CHECK block below pins.
;
; ⚠ RECORDING a `PrepRegionIdxs` edge for a kickback would be WRONG, not merely
; redundant: it demands the OPPOSITE order and would close a precedence CYCLE,
; declining the whole module through the Kahn backstop.
;
; ⚠ RED ON THE ORACLE (`branch phase on a bare i1 condition`, `59ac5b7`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %mid
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %mid
mid:
  %c = icmp eq i32 %q, 5
  br i1 %c, label %ph2, label %done
ph2:
  call void @cq_phi(double 1.100000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 1.100000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[HQ]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-2: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
