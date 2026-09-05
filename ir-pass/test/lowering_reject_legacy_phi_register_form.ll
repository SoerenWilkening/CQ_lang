; lowering_reject_legacy_phi_register_form.ll — DECLINE. THE RETIRED
; `@cq_phi_<sfx>(x, angle)` REGISTER FORM (bd test_C_libtooling-3qlq Inc 1,
; PRD `retire-swap-route-PRD.md` §4.1).
;
; `CQ.h` no longer declares the 15-width family and `resolveSources` no longer
; RESOLVES it, so `@cq_phi_si32` is an ordinary unknown external — and a tainted
; value reaching one declines through `declineTaintEscapes` like any other opaque
; callee. This fixture PINS that disposition, because "the old spelling stops
; being recognized" is the whole surface half of the increment and nothing else
; would notice if the resolver quietly took it back.
;
; WHY IT MUST NOT KEEP LOWERING (PRD §1). It used to become `cqrt_rz_<W>`, which
; the ABI pins as TENSORED — Rz on EACH qubit of the register. Under control that
; put phase `(-1)^popcount(target)` on the marked branch, and `|0..0>` could not
; be marked at all because a per-qubit diagonal gate FIXES it. Every shipped
; Grover golden was a self-consistent trace of the IDENTITY on `q`; the golden
; byte-diff cannot see that (Rule 2) and there is no simulator.
;
; THE DECLINE IS THE POINT, NOT A GAP. A program on the old spelling fails to
; COMPILE against the new header (there is deliberately no migration shim), so
; this IR can only come from hand-writing or a stale header — and in either case
; a loud refusal is strictly better than a wrong unitary.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_phi_si32(i32 %q, double 3.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq taint escape: tainted value consumed by an unknown callee
