; control_angle_select_phase_runtime.ll — ACCEPT. RUN-TIME ANGLE ARMS, admitted
; for the REGISTER-FREE PHASE stem and ONLY for it (PRD §12 owner question Q3,
; assumed answer YES; §3 "Angle select").
;
; THE TWO STEMS NOW HAVE OPPOSITE DISPOSITIONS ON ONE INPUT SHAPE, so pin both
; directions. Its twin `control_angle_select_ry_reject_runtime_arms.ll` is the Ry
; half and still DECLINES; deleting either file leaves the split unpinned.
;
; WHY THE SPLIT IS THE ARITHMETIC AND NOT A POLICY. 2b's Ry lowering emits an
; unconditional `R(h, B)` plus ONE `R_controlled(f, h, A−B)`, so it must COMPUTE
; `A − B`. The clearance review (blocker F-11) measured what that costs with
; run-time arms: the realized true-arm angle is `B + fl(A−B)`, whose error is
; unbounded in ABSOLUTE radians — 0.858 rad from plain C with π and 1e16, i.e.
; `Ry(π)` realized as `Ry(4.0)` — and `fl(A−B)` can be `inf` from two FINITE arms
; (±8.99e307). Neither is fenceable at compile time, so run-time arms were
; narrowed OUT.
;
; THIS STEM SUBTRACTS NOTHING. Each arm's value is passed VERBATIM into its own
; `cqrt_rz_i1`, so `%a` and `%b` appear in the emitted gates unchanged and no
; `fsub` exists anywhere in the module. There is no rounding residual to bound,
; and `angleSelectArmsAdmissible` — the whole fence — is not asked at all.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %a, double %b
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE ARMS ARE PASSED THROUGH, BY SSA NAME — this is the assertion that separates
; this lowering from the by-difference one: `%a` and `%b` themselves reach the
; gates, so no value the source did not name enters a gate slot.
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so every count lives in its own GCNT prefix and NOROUTE carries no positives).
;
; The four things a register-free kickback must NEVER emit:
;   * a route of any kind — the whole point is that no work rail exists;
;   * a `_controlled` gate — the gate is UNCONTROLLED, on the flag ancilla;
;   * `cqrt_rz_<W>` for W != i1 — the TENSORED per-register Rz is the defect
;     this increment removes (PRD §1: it marks `(-1)^popcount(target)` and can
;     never mark |0..0>, which made every Grover golden the identity on q);
;   * a surviving `@cq_phi` CALL — it is lowered here or deleted (D2), never
;     left for the linker.
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
; NOROUTE-NOT: fsub
; NOROUTE-NOT: = select

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-2: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_x(
; C2-NOT:     call void @cqrt_x(
; C3-COUNT-1: call void @cqrt_free(
; C3-NOT:     call void @cqrt_free(
