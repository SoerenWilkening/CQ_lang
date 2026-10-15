; control_inplace_ry_reject_mergephi_root_measured.ll — DECLINE: the phi root is measured before the branch.
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
;   if (a) Ry(t,.3); m = cq_measure(t); if (t) Ry(u,.2);   rung (ii).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

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
  %6 = call i1 @cq_measure_i1(i1 %5)
  br i1 %5, label %7, label %9

7:
  %8 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  br label %9

9:
  %10 = phi i1 [ %8, %7 ], [ false, %4 ]
  %11 = zext i1 %6 to i32
  %12 = call i1 @cq_measure_i1(i1 %1)
  %13 = zext i1 %12 to i32
  %14 = add nuw nsw i32 %13, %11
  %15 = call i1 @cq_measure_i1(i1 %10)
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %14, %16
  ret i32 %17
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
