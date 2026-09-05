; control_angle_select_phase_constants.ll — ACCEPT. P2, the ANGLE SELECT on the
; REGISTER-FREE PHASE stem (PRD §6.2 row P2, §3 "Angle select").
;
;     if (q == 5) cq_phi(0.9); else cq_phi(0.3);
;
; MEASURED: `clang -O1` never hands that source to the pass as a diamond —
; SimplifyCFG sinks both calls into ONE `call void @cq_phi(double %sel)` with
; `%sel = select i1 %c, double A, double B`.
;
; THE LOWERING IS EXACT AND PERFORMS NO ARITHMETIC:
;     x(f); rz_i1(f, B); x(f);   // P(B) on the f = 0 branch
;     rz_i1(f, A)                // P(A) on the f = 1 branch
; Under `Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` that gives |0> the factor
; `e^{i(B−A)/2}` and |1> the factor `e^{i(A−B)/2}` — a RELATIVE phase of
; `e^{i(A−B)}`, which is what `P(A)`-on-1 / `P(B)`-on-0 produces, times an
; unobservable global phase.
;
; CONTRAST WITH THE Ry STEM, which is UNCHANGED and must stay so: 2b lowers that
; one BY DIFFERENCE (`R(h,B)` unconditional + one `R_controlled(f,h,A−B)`), which
; realizes `A − B` as a `double` the source never wrote — hence its whole
; arm-value fence and the clearance narrowing to CONSTANT arms (finding F-11).
; None of that has a subject here; see `control_angle_select_phase_runtime.ll`.
;
; THERE IS NO POLARITY CASE. A `select` means "A when the condition is 1", full
; stop — unlike a `br` diamond, whose gate arm `clang -O1` often makes the FALSE
; successor. The `cqrt_x` bracket here is not a polarity fix: it is how the
; f = 0 branch's gate is expressed at all.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 9.000000e-01)
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
; ⚠ ONE COMPLEMENT PATTERN, NOT SIX ENUMERATED WIDTHS — Rule-13 round-1 findings
; F-L6-4 / F-L8-1 / F-L4-2. The shipped ABI has NINE Rz widths
; (`runtime/cq_runtime.h`: i1, i8, i16, i32, i64, f16, f32, f64, f80) and the
; enumeration listed SIX: `f16` and `f80` were absent from ALL of these fixtures,
; so the block's own claim ("no TENSORED Rz at any width") was 6/8 true.
; MEASURED by injection into this file's own pass output: `cqrt_rz_i32` was
; caught, `cqrt_rz_i1` was caught by the count prefix, and `cqrt_rz_f80` /
; `cqrt_rz_f16` were NOT. The regex below is validated in BOTH directions —
; it fires on an injected `cqrt_rz_i16` and does NOT fire on the clean output's
; `cqrt_rz_i1`, which is the one case a bare prefix test gets wrong (`cqrt_rz_i1`
; is a textual prefix of `cqrt_rz_i16`), so the trailing `(` is load-bearing.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
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
; C3-COUNT-1: call i32 @cq_template_icmp_eq_i32_hl(
; C3-NOT:     call i32 @cq_template_icmp_eq_i32_hl(
; C4-COUNT-1: call void @cqrt_free(
; C4-NOT:     call void @cqrt_free(
