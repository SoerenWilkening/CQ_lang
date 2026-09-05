; control_phase_kickback_derived_cond.ll — ACCEPT. A DERIVED condition register,
; and the exact IR shape of the D4 PER-BIT idiom.
;
;     if ((q >> i) & 1) cq_phi(theta);      // one bit of a register-wide Rz
;
; `clang -O1` rewrites that condition to `and(q, 1<<i)` compared against 0, so the
; arm is the FALSE successor (the `cqrt_x` bracket) and the compare reads a
; DERIVED rail, not `q` itself. The `and` therefore mints its own rail, which the
; whole-DAG uncompute spine reverses (`..._hl_unc`) and frees — so this fixture
; also pins that a kickback composes with the ordinary data-lowering spine rather
; than short-circuiting it.
;
; PRD §9 records the per-bit idiom as the DOCUMENTED replacement for the deleted
; multi-bit Rz (owner decision D4: the width-only ABI cannot address a qubit, so
; "Rz on qubit i" is a Phase-9 BACKEND peephole over exactly this fixed gate
; sequence). MEASURED elsewhere in this increment: the loop form lowers ROLLED
; with IR size independent of the bit count (23 `@slice` lines at K=4 AND K=32).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C5 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = and i32 %q, 8
  %c = icmp eq i32 %b, 0
  br i1 %c, label %merge, label %arm
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The phase lands on the FLAG minted from the DERIVED rail, and the derived rail
; is uncomputed and freed by the ordinary spine afterwards.
; CHECK:      %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 8)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[D]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[D]], i32 0)

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

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_x(
; C2-NOT:     call void @cqrt_x(
; C3-COUNT-1: call i32 @cq_template_and_i32_hl(
; C3-NOT:     call i32 @cq_template_and_i32_hl(
; C4-COUNT-1: call void @cq_template_and_i32_hl_unc(
; C4-NOT:     call void @cq_template_and_i32_hl_unc(
; C5-COUNT-2: call void @cqrt_free(
; C5-NOT:     call void @cqrt_free(
