; control_inplace_ry_reject_stateprep_mbeta_ifelse_rechain.ll — DECLINE (F2).
;
; ⚠ THE SECOND OF THE TWO TRIPWIRES for the M-beta RAUW-TARGET invariant (bd
; `test_C_libtooling-om35`, round-2 Rule-13 review F-F1-5 / F-F2-1). Its sibling
; is `control_inplace_ry_reject_stateprep_mbeta_base_offcone.ll`, whose header
; carries the full statement of the invariant; read it first. This file covers
; the M-beta spelling that sibling does NOT: the **IF/ELSE RE-CHAIN**.
;
; WHY A SECOND SPELLING IS OWED. M-beta has three forms and only one of them
; RAUWs the merge phi to a value that was already an instruction before emission:
;   * diamond, un-negated — target is `T` itself, `moveBefore(BI)`: the arm
;     incoming, unchanged;
;   * **IF/ELSE (two content arms) — target is `T2`, after
;     `G.first->setArgOperand(0, Prev)` at `SwapRouteEmit.cpp:948` chains `T2`
;     onto `T1`. That is a GENUINELY NEW SSA EDGE, and it is the one this file
;     exercises**;
;   * negated rail arm — target is `TNeg`, a CLONE created at emission
;     (`:917` `setArgOperand(0, T)`, `:930` the fneg'd angle).
; In every case the target's operand roots were already reachable from the phi
; (for the if/else form, `%MA` used BOTH `%ta` and `%ta2`, so reaching `%ta2`
; after the re-chain still requires reaching what reached it before). The purpose
; of this file is that the middle bullet be MEASURED and not merely argued.
;
; WHAT THIS MODULE IS. Identical to the sibling except that region A is an
; IF/ELSE with two in-place Ry arms (`%armA` / `%armA2`, merging at `%mA`), so
; the emitter takes the `:948` path. Region B is still the round-2 state prep on
; `icmp eq i32 %out, 13` with seed `i32 0`; the collider `%zm` is still a user of
; region A's merge phi and folds to `{0}` == the seed on B's true edge; region A's
; base `%q2` is still OFF `%MB`'s cone.
;
; WHAT WOULD MAKE IT GO GREEN. Exactly as the sibling: if the re-chain ever
; produced a target reachable from `%MB`, `%zm` would become a manufactured
; `%MB`-descendant, be excluded from the collider set, and this file would
; ACCEPT. It declines on all three binaries of the increment today (ORACLE
; `f7b65d8c…`, un-narrowed `147cb3d6…`, subject `96fdd3a9…`).
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}
define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 0, double 7.500000e-01)
  %c1 = icmp eq i32 %q, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %m1 ]
  %c3 = icmp eq i32 %q, 7
  br i1 %c3, label %armA, label %armA2
armA:
  %ta = call i32 @cq_theta_si32(i32 %q2, double 2.500000e-01)
  br label %mA
armA2:
  %ta2 = call i32 @cq_theta_si32(i32 %q2, double 1.250000e-01)
  br label %mA
mA:
  %MA = phi i32 [ %ta, %armA ], [ %ta2, %armA2 ]
  %dz = zext i32 %out to i64
  %dd = add i64 %dz, -13
  %mz = zext i32 %MA to i64
  %pm = mul i64 %dd, %mz
  %zm = trunc i64 %pm to i32
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %MA)
  %x2 = call i32 @cq_measure_si32(i32 %zm)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; CHECK-NOT: cqrt_alloc_i32
