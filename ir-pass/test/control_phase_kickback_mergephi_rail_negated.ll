; control_phase_kickback_mergephi_rail_negated.ll — ACCEPT (bd `3qps`, Track P).
; THE POLARITY `clang -O1` ACTUALLY PRODUCES for the owner's spelling: the prep
; arm is the FALSE successor (Rule 9 — `-O1` canonicalizes and swaps), so
; `emitInPlaceRotationRegion` emits the UNCONDITIONAL `ry` plus a CONTROLLED
; CANCELLING `ry(−θ)` (the "negated controlled Ry by ADDITIVITY" convention:
; nothing NON-diagonal may be `cqrt_x`-bracketed on a user register) and M-β's
; RAUW target is the chained clone.
;
; Read as a PAIR with `control_phase_kickback_mergephi_rail.ll`: same construct,
; opposite prep polarity, and the kickback half — `cqrt_rz_i1(h1, φ)`, no mint,
; no bracket, no strip, no free — is IDENTICAL. That is the claim the widening
; makes: it changes WHICH values may be a control, never WHAT is emitted on them.
;
; ⚠ RED ON THE ORACLE (`branch phase on a bare i1 condition`, `59ac5b7`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %merge, label %arm
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: cqrt_cnot
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
