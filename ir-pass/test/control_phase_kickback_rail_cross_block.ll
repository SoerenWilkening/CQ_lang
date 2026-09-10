; control_phase_kickback_rail_cross_block.ll — ACCEPT (bd 3qlq.4): the rail is
; DEFINED IN A DIFFERENT BLOCK than its branch (a classical `if (g)` rotating an
; unrelated register sits between). A COMPARE condition in this position is the
; documented over-decline (`condWireDisposition`'s same-block prong — the LICM
; `hoisted compare` fixture); a RAIL has no compare-to-branch window to bound, so
; `railCondWireDisposition` deliberately drops that prong and asks only the wire:
; no non-diagonal gate on `b`'s wire that is not provably post-branch. This file
; is the discriminator for "minus that prong".

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

define i32 @example(i1 %u0, i32 %u1, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %rot, label %pred
rot:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 1.000000e-01)
  br label %pred
pred:
  %qq = phi i32 [ %q2, %rot ], [ %q, %entry ]
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i32 @cq_measure_si32(i32 %qq)
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[Q:[a-zA-Z0-9_.]+]], double 1.000000e-01)
; CHECK:      call void @cqrt_rz_i1(i32 %[[H]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: {{.*}} = call i1 @cqrt_measure_i1(i32 %[[H]])

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
; FCNT-NOT: call void @cqrt_free(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
