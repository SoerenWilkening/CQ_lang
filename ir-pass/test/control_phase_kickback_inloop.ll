; control_phase_kickback_inloop.ll — ACCEPT, ROLLED. P6: a kickback region inside
; a classically-bounded loop (PRD §6.2 row P6; the 8h7d.5 rolled in-loop path).
;
; This is Grover written as `for (i = 0; i < K; i++) { oracle; diffusion; }`. The
; region is admitted only through `flatRegionRollableInLoop` — the SAME 8h7d.5
; predicate the flat phase path uses, asked from the kickback classifier's own
; pre-peel rather than re-spelled (Rule 14; it is declared in `ControlShape.h` for
; that reason). Everything else on a cycle (irreducible, multi-latch, nested)
; keeps its existing decline and its existing string.
;
; WHAT A KICKBACK NEEDS FROM THE ROUND-2 RAIL COLLAPSE: NOTHING. It emits no gate
; on the loop-carried register at all, so `collapseFlattenedLoopRails` finds
; nothing to collapse for it and `staleRailRecordRead` has no rail record to
; invalidate. Every ancilla it mints — the flag — is stripped and freed INSIDE the
; iteration, so nothing crosses the back edge.
;
; THE PROPERTY THIS PINS is that the BACK EDGE SURVIVES and the body holds
; EXACTLY ONE `cqrt_rz_i1`: the IR is rolled, not unrolled, so its size is
; independent of the trip count (MEASURED elsewhere in this increment at K=3 and
; K=1000: 25 identical `@slice` lines).
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
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c = icmp eq i32 %q0, 5
  br i1 %c, label %arm, label %body
arm:
  call void @cq_phi(double 3.14159265358979323846)
  br label %body
body:
  br label %latch
latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %q0)
  ret i32 %m
}

; THE LOOP IS STILL A LOOP — the header phi survives — and the mint / gate /
; strip / free quadruple sits INSIDE its body, ONCE. Every one of those four is
; per-iteration, so no ancilla crosses the back edge.
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %{{.*}} ], [ %{{.*}}, %latch ]
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; …and the BACK EDGE is intact: the latch still re-enters the header.
; CHECK:      br i1 %{{.*}}, label %exit, label %head

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
; ⚠ AND THE UNPAIRED-POLARITY NEGATIVE, ADDED BY THE RULE-13 ROUND-1 REVIEW
; (F-L8-2). This shape emits NO `cqrt_x` at all — its arm is the TRUE successor —
; so an injected or mis-emitted bracket gate would have passed every directive in
; this file silently. A `cqrt_x` on the flag is not cosmetic: an UNPAIRED one
; inverts which branch the phase lands on, i.e. a different unitary.
; NOROUTE-NOT: call void @cqrt_x(

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-1: call i32 @cq_template_icmp_eq_i32_hl(
; C2-NOT:     call i32 @cq_template_icmp_eq_i32_hl(
; C3-COUNT-1: call void @cq_template_icmp_eq_i32_hl_unc(
; C3-NOT:     call void @cq_template_icmp_eq_i32_hl_unc(
; C4-COUNT-1: call void @cqrt_free(
; C4-NOT:     call void @cqrt_free(
; C5-COUNT-1: br label %head
; C5-NOT:     br label %head
