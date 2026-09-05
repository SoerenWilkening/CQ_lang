; control_phase_kickback_f64_cond.ll — ACCEPT. An `fcmp` CONDITION.
;
; The flag mint is stem-agnostic — it is `CompareLowering::lowerCompareToFlag`,
; the same one every other control path uses — so an f64 register compared against
; a classical `double` mints `cq_template_fcmp_olt_f64_hl` and the kickback stream
; is otherwise byte-for-byte the integer one.
;
; ⚠ DO NOT READ THIS AS "fp under control is admitted" — the fp/angle distinction
; is untouched here. What is f64 is the CONDITION REGISTER; the ANGLE is a
; classical `double` literal as always (Rule 3), and there is no fp DATA merge
; anywhere in the region (a kickback merges no data at all). The f64-merge-phi
; miscompile family (`isFPOrFPVectorTy`, "a floating-point merge phi is an ANGLE,
; not data") is about a different wire and keeps its declines.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll

declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 2.500000e+00
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], double 2.500000e+00)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 2.500000e+00)
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
; NOROUTE-NOT: call void @cqrt_x(

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-1: call i32 @cq_template_fcmp_olt_f64_hl(
; C2-NOT:     call i32 @cq_template_fcmp_olt_f64_hl(
; C3-COUNT-1: call void @cq_template_fcmp_olt_f64_hl_unc(
; C3-NOT:     call void @cq_template_fcmp_olt_f64_hl_unc(
; C4-COUNT-1: call void @cqrt_free(
; C4-NOT:     call void @cqrt_free(
