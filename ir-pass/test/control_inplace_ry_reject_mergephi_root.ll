; control_inplace_ry_reject_mergephi_root.ll — **NOW AN ACCEPT**: a prep's merge phi as the whole Ry condition.
;
; ⚠ The `reject_` in the name is history (bd `gahu` precedent, L8): this file
; pinned the over-decline and its retirement trigger ("flip when the Ry phi-root
; row lands") fired here.
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
;   bool a (rotated), t = 0, u = 0; if (a) cq_theta(&t,.3); if (t) cq_theta(&u,.7);
; Trace: t = cRy(a, .3) on a fresh rail; u = cRy(t_rail, .7) on a fresh rail.
; a=0: t=|0>, u=|0>; a=1: t = Ry(.3)|0>, u = Ry(.7)|0> on t's |1> branch.
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
  br i1 %1, label %2, label %4

2:
  %3 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %4

4:
  %5 = phi i1 [ %3, %2 ], [ false, %0 ]
  br i1 %5, label %6, label %8

6:
  %7 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %8

8:
  %9 = phi i1 [ %7, %6 ], [ false, %4 ]
  %10 = call i1 @cq_measure_i1(i1 %1)
  %11 = zext i1 %10 to i32
  %12 = call i1 @cq_measure_i1(i1 %5)
  %13 = zext i1 %12 to i32
  %14 = add nuw nsw i32 %13, %11
  %15 = call i1 @cq_measure_i1(i1 %9)
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %14, %16
  ret i32 %17
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
