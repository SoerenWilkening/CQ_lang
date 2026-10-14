; control_inplace_ry_mergephi_root_prepped_target.ll — ACCEPT: merge phi root, PREPPED target (chained Ry).
;
; bd test_C_libtooling-dm7f.53 (R11 round-1 item 2) — a claimed REGION-MERGE
; phi as the WHOLE condition of an in-place controlled Ry / state prep. It is
; the one-leaf tree `collectCondTree` returns for a phi root, admitted by the
; leaf ladder (`condTreePhiLeafRefusal`: claimed InPlaceRotation merge,
; tainted, not measured before the branch) and lowered as a REGISTER-AS-CONTROL
; exactly like a bare `_Bool` rail (`PhiRootCond` / `RegCond` in
; `classifyArms`): `cqrt_ry_<W>_controlled(t_rail, u, θ)`, the phi never minted,
; bracketed or freed; a negated arm is `ry(u,θ); ry_controlled(t,u,−θ)`. The
; region is emitted before the prep that owns the phi (hcrg alias edge, or
; `PrepRegionIdxs` cross-block); the wire question is the kickback phi root's
; (`condWireDisposition` with `CondIsClaimedRailPhi` and the covered producer
; gates; a cross-block phi asks the wire-scoped `crossBlockPhiLeafMintable`).
;
;   u Ry(.1); if (a) Ry(t,.3); if (t) Ry(u,.2);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  br i1 %1, label %3, label %5

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  br i1 %6, label %7, label %9

7:
  %8 = call i1 @cq_theta_i1(i1 %2, double 2.000000e-01)
  br label %9

9:
  %10 = phi i1 [ %8, %7 ], [ %2, %5 ]
  %11 = call i1 @cq_measure_i1(i1 %1)
  %12 = zext i1 %11 to i32
  %13 = call i1 @cq_measure_i1(i1 %6)
  %14 = zext i1 %13 to i32
  %15 = add nuw nsw i32 %14, %12
  %16 = call i1 @cq_measure_i1(i1 %10)
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %15, %17
  ret i32 %18
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 1.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H2]], i32 %[[H1]], double 2.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
;
; Whole-file, pure negatives (a positive in a prefix windows the negatives
; after it): no route / copy / adjoint gate, every arm theta and region phi
; consumed; FCNT/CRCNT count the frees and the controlled Ry gates.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: zext i1 {{.*}} to i8
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
