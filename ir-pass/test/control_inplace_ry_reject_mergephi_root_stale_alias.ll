; control_inplace_ry_reject_mergephi_root_stale_alias.ll — DECLINE: the branch reads a STALE alias of the phi.
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
;   if (a) Ry(t,.3); if (c) Ry(t,.4); bool k = t; Ry(t,.9); if (k) Ry(u,.2);
; `k` aliases t's register, which the unconditional Ry(.9) relabels before the
; read: the wire walk sees the gate on the phi's own wire (loud).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 6.000000e-01)
  %3 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  br i1 %1, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 %3, double 3.000000e-01)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ %3, %0 ]
  br i1 %2, label %8, label %10

8:
  %9 = call i1 @cq_theta_i1(i1 %7, double 4.000000e-01)
  br label %10

10:
  %11 = phi i1 [ %9, %8 ], [ %7, %6 ]
  %12 = call i1 @cq_theta_i1(i1 %11, double 9.000000e-01)
  br i1 %11, label %13, label %15

13:
  %14 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  br label %15

15:
  %16 = phi i1 [ %14, %13 ], [ false, %10 ]
  %17 = call i1 @cq_measure_i1(i1 %1)
  %18 = zext i1 %17 to i32
  %19 = call i1 @cq_measure_i1(i1 %12)
  %20 = zext i1 %19 to i32
  %21 = add nuw nsw i32 %20, %18
  %22 = call i1 @cq_measure_i1(i1 %16)
  %23 = zext i1 %22 to i32
  %24 = add nuw nsw i32 %21, %23
  %25 = call i1 @cq_measure_i1(i1 %2)
  %26 = zext i1 %25 to i32
  %27 = add nuw nsw i32 %24, %26
  ret i32 %27
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
