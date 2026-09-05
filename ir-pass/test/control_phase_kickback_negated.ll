; control_phase_kickback_negated.ll — ACCEPT. The `cqrt_x` BRACKET (Rule 9).
;
; Byte-identical to `control_phase_kickback_diamond.ll` except the branch's two
; successors are SWAPPED, so the gate arm is the FALSE successor — which is what
; `clang -O1` canonicalizes `if (q != 5)` into, and therefore the polarity a real
; program is at least as likely to arrive in as the other one.
;
; The gate then fires on ¬f, spelled with the self-inverse `cqrt_x(f)` pair that
; every other "fires on ¬f" emission in this tree uses (one pair per ARM, not per
; gate — `cqrt_x` is an involution, and `SwapRouteEmit.cpp`'s `-2 cqrt_x` audit
; arithmetic assumes exactly this). Nothing else about the stream changes: same
; mint, same single `cqrt_rz_i1`, same strip, same free.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %merge, label %arm
arm:
  call void @cq_phi(double 3.14159265358979323846)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
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

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_x(
; C2-NOT:     call void @cqrt_x(
; C3-COUNT-1: call void @cqrt_free(
; C3-NOT:     call void @cqrt_free(
