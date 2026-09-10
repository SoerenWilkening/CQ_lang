; control_phase_kickback_rail_and_rail.ll — ACCEPT (bd 3qlq.4): TWO rail leaves
; under one AND node — `if (b && c) cq_phi(φ)` with both `_Bool`. No template is
; minted anywhere: one Toffoli from the two registers into `g`, the phase on
; `g`, the Toffoli again, `free(g)`. Both registers survive untouched to their
; measurements (FCNT 1 = `g` only; MINT 0).

; bd test_C_libtooling-3qlq.4 (Inc 1b) — the BARE RAIL CONDITION. `_Bool b =
; cq_theta(b0, θ)` is a one-qubit REGISTER, and `if (b) …` hands the pass
; `br i1 %b` with no compare to mint a flag from. The register IS the flag: the
; kickback gate `cqrt_rz_i1(h_b, θ)` sits directly on `b`'s rail — NO mint, NO
; `_unc` strip, NO `cqrt_free` (the rail is the user's), and NO `cqrt_x` on a
; user register EVER: a gate that fires on `b == 0` is the diagonal
; `rz(h_b, −θ)`, on `X·P(θ)·X = diag(e^{iθ},1) = e^{iθ}·P(−θ)` (equal up to the
; global phase owner decision D2 already discards; `fneg` is exact in IEEE).
; Unitary: `P(θ)` on `b` multiplies exactly the `|b=1⟩` branch by `e^{iθ}`,
; which IS the source's meaning; nothing is left behind, so every later read of
; `b` (measure, compare, arithmetic, a chained Ry) sees the same basis label.
; `SwapRouteEmit.cpp` (`emitKickbackGroup`), `SelectClassify.h` (`RailLeaves`).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i1 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %u1, double 3.000000e-01)
  %s = select i1 %b, i1 %c, i1 false
  br i1 %s, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i1 @cq_measure_i1(i1 %c)
  %y = zext i1 %n to i32
  %r = add i32 %y, %z
  ret i32 %r
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u1)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[C]], double 3.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H]], i32 %[[C]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H]], i32 %[[C]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: {{.*}} = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK:      {{.*}} = call i1 @cqrt_measure_i1(i32 %[[C]])

; ---- Whole-file negatives (pure-negative prefix: NO positive line may sit
; inside it, or every later negative is WINDOWED — the Inc-4 F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_
; ACNT-COUNT-3: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
