; control_phase_kickback_rail_data_use.ll — ACCEPT (bd 3qlq.4): the register is
; read as DATA after the phase (`int s = q + b` — a `zext` chain BORROWING the
; rail as a parent, lowered out of place and discharged by the whole-DAG spine).
; This is the file that pins WHY a `¬rail` gate is `rz(−θ)` and never a `cqrt_x`
; bracket: `Uncomputation::preservesBorrowedParent` admits an uncontrolled
; `cqrt_rz_` on the borrowed parent BY NAME (diagonal — the basis label the
; `zext` copied is unchanged) and FAILS CLOSED on anything it does not name, so
; with a bracket this chain would freeze and leak `h_cast`. Pinned: the zext's
; `_unc` and ONE free (`h_cast`), the register itself never freed.

; bd test_C_libtooling-3qlq.4 (Inc 1b) — the BARE RAIL CONDITION. `_Bool b = b0;
; cq_theta(&b, θ)` is a one-qubit REGISTER, and `if (b) …` hands the pass
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

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %z = zext i1 %b to i32
  %s = add i32 %q, %z
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[Q]], i32 %[[Z]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[Z]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT: {{.*}} = call i32 @cqrt_measure_i32(i32 %[[S]])
; CHECK-NOT: call void @cqrt_free(i32 %[[H]])

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
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-COUNT-1: call i32 @cq_template_zext_i1_to_i32(
; MINT-COUNT-1: call i32 @cq_template_add_i32(
; MINT-COUNT-1: call void @cq_template_zext_i1_to_i32_unc(
; MINT-NOT: call void @cq_template_
; MINT-NOT: call i32 @cq_template_
