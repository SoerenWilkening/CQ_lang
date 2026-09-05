; control_phase_switch_kickback_multigate.ll — ACCEPT. P5 with N GATES in one
; case arm.
;
; N gates on one eq-flag need no arithmetic: each angle is passed through
; VERBATIM and `P(θ1)·P(θ2)·P(θ3) = P(θ1+θ2+θ3)` happens in the HARDWARE, not in
; this compiler — so there is no `fsub`, no rounding residual and no bound to
; fence, unlike the 2b by-difference Ry form. It is the same reasoning the flat
; kickback's N-gate arm rests on (orchestrator decision 2026-09-05, superseding
; PRD §6.3's first decline row, whose stated ground is a Ry-stem ground).
;
; There is exactly ONE mint, ONE strip and ONE free for the three-gate case: the
; flag is per CASE, not per gate.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %a0
    i32 1, label %a1
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  call void @cq_phi(double 2.500000e-01)
  call void @cq_phi(double 2.750000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V2]], double 1.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V2]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V3]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V3]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V3]], double 2.750000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so counts live in their own prefixes and NOROUTE carries no positives). The
; four things a register-free kickback must NEVER emit: a route of any kind, a
; `_controlled` gate, a `cqrt_rz_<W>` for W != i1 (the TENSORED per-register Rz
; PRD §1 records as the defect), and a surviving `@cq_phi` call.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: cqrt_rz_i8
; NOROUTE-NOT: cqrt_rz_i16
; NOROUTE-NOT: cqrt_rz_i32
; NOROUTE-NOT: cqrt_rz_i64
; NOROUTE-NOT: cqrt_rz_f32
; NOROUTE-NOT: cqrt_rz_f64
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_

; ---------------------------------------------------------------------------
; COUNTS. FOUR `cqrt_rz_i1` (1 + 3) but only TWO mints and TWO frees: the flag is
; per CASE, not per gate. A third free would be a spurious uncompute free — a
; hidden measurement that collapses `q` (Rule 6).
; C1-COUNT-4: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_free(
; C2-NOT:     call void @cqrt_free(
