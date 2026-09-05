; control_phase_kickback_diamond.ll — ACCEPT. THE FLAGSHIP P1 SHAPE (bd
; test_C_libtooling-3qlq Inc 1, PRD `retire-swap-route-PRD.md` §6.2 row P1).
;
;     if (q == 5) cq_phi(PI);        // the Grover oracle, marking |5>
;
; A flat tainted-condition DIAMOND whose arm is exactly one register-free
; `call void @cq_phi(double)` and a `br`. It has NO MERGE PHI — `cq_phi` returns
; nothing — which is exactly why `recoverRegion` cannot see it (all three of its
; recognizers require a non-null `soleMergePhi`) and why detection PRE-PEELS it,
; the seam `classifyAbortPark` and `lowerControlledIOSinks` already sit in.
;
; The emitted stream IS the increment: mint the condition flag into a |0> ancilla,
; put the phase ON THE FLAG with an UNCONTROLLED `cqrt_rz_i1`, let the ordinary
; compare `_unc` return the flag to |0> on every branch, free it. The register `q`
; is an operand of NOTHING here but the compare.
;
; WHAT IT REPLACES, and why the replacement is the whole point (PRD §1): the
; pre-3qlq binary lowered `q = cq_phi(q, PI)` in this arm to
; `cqrt_rz_i32_controlled(f, h, PI)`, and `cqrt_rz_<W>` is TENSORED — Rz on EACH
; qubit — so the marked branch got `(-1)^popcount(5) = +1` and `|0..0>` could not
; be marked at all. Every shipped Grover golden was a self-consistent trace of the
; IDENTITY on q, invisible to the byte-diff (Rule 2).
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
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.14159265358979323846)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE FOUR-LINE KICKBACK, IN ORDER. The flag is minted from the compare, the
; phase lands ON THE FLAG, the strip names the SAME flag (so the golden itself
; witnesses the pairing, bd 8txa) and the free follows it immediately.
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18)
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
