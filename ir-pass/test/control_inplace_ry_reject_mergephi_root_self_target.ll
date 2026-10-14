; control_inplace_ry_reject_mergephi_root_self_target.ll — DECLINE: the Ry target IS the phi root's register.
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
;   if (a) Ry(t,.3); if (t) Ry(t,.7);   a self-controlled rotation (bd dm7f.51 /
; dm7f.9 territory), loud at the state-prep F1 fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  br i1 %1, label %2, label %5

2:
  %3 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %4 = zext i1 %3 to i8
  br label %5

5:
  %6 = phi i8 [ %4, %2 ], [ 0, %0 ]
  %7 = trunc nuw i8 %6 to i1
  br i1 %7, label %8, label %11

8:
  %9 = call i1 @cq_theta_i1(i1 true, double 0x3FE6666666666666)
  %10 = zext i1 %9 to i8
  br label %11

11:
  %12 = phi i8 [ %10, %8 ], [ %6, %5 ]
  %13 = call i1 @cq_measure_i1(i1 %1)
  %14 = zext i1 %13 to i32
  %15 = trunc nuw i8 %12 to i1
  %16 = call i1 @cq_measure_i1(i1 %15)
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %17, %14
  ret i32 %18
}

; CHECK: cq controlled lowering: state prep merged with a quantum register under quantum control
