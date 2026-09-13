; lowering_reject_measure_undef_operand.ll — DECLINE: a `cq_measure` whose operand
; is an `undef` / `poison` LITERAL. bd test_C_libtooling-21mg verdict (a).
;
; 21mg makes a measure of a CLASSICAL value lower to that value (no gate, no
; rail, no trace line). An `undef`/`poison` operand is the one classical operand
; that is NOT a value: at the `-O0` stage-3 link one `undef` token may be
; materialized differently at each use (the `LiteralIntegrity` /
; `declineUnpairedUndefLiterals` posture — an undef literal in two slots read as
; two values), so the outcome this "measurement" reports is not reproducible and
; the golden byte-diff contract has nothing to pin (Rule 2). The frontend agrees
; already: every `cq_measure_<sfx>` parameter carries `noundef`, so an `undef`
; there is a contract violation, and reaching one means the source read an
; uninitialized object — UB in C, with no circuit (trivial or otherwise) to emit.
; Over-declining is safe (Prime Directive); a silently arbitrary measurement
; outcome is the unforgivable direction.
;
; ⚠ THE C CUSTOMER IS REAL, not hand-IR-only: `bool b; return cq_measure(b);`
; compiles at `-O1` to `call i1 @cq_measure_i1(i1 noundef zeroext undef)`
; (measured 2026-09-13, probe `trackC/probes/c6_undef_bool.c`).
;
; The `poison` spelling is the SAME predicate and needs no second function here:
; `PoisonValue` derives from `UndefValue`, and the shared `valueCarriesUndef`
; (LiteralIntegrity.cpp — Rule 14, one spelling) answers both, plus an undef
; nested inside a `ConstantExpr`/aggregate. Measured on the subject binary as
; probe `c6b` (`i32 poison`), same message; `LLVMContext::diagnose` exits at the
; FIRST `DS_Error`, so a second function in this file would never be reported and
; would pin nothing (Rule 12 (c)).
;
; RED-GREEN: on the ORACLE (`main` e96f89c / 86c0d25) this module declines with
; `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` — the
; blanket over-decline 21mg removes — so this fixture is RED there on the STRING.
; It must stay a DECLINE, on the undef message, on every later binary.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOCLASSICAL
declare i1 @cq_measure_i1(i1)

define i1 @undef_operand() {
entry:
  %m = call i1 @cq_measure_i1(i1 undef)
  ret i1 %m
}

; CHECK: error{{.*}}cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value

; ⚠ Rule 12 (b): a `DS_Error` decline writes 0 bytes to stdout, so the property
; below is pinned by the `not` inversion on the RUN line, not by this text — the
; NOT lines exist so a binary that turns this into an ACCEPT (passing the undef
; through, or minting a rail for it) fails on the `not` AND names what went wrong.
; NOCLASSICAL-NOT: cqrt_alloc
; NOCLASSICAL-NOT: cqrt_measure_
