; lowering_reject_taint_escape_opaque_call.ll — DECLINE: tainted value consumed
; by an OPAQUE (declared-only) call in a NON-angle, DATA position
; (test_C_libtooling-bxv).
;
; `%r = call i32 @ext(i32 %q)` is same-typed (i32 -> i32), so unlike the
; cross-type-RAUW cast family (which the verifier catches) it survives lowering
; WELL-TYPED: nothing lowers an opaque call, so after rotation lowering's RAUW
; (%q -> i32 runtime handle) the surviving `@ext` call reads the RUNTIME HANDLE
; TAG, and `cqrt_measure_i32(%r)` then measures @ext's CLASSICAL return as a
; "handle" — verify-clean, links, runs, prints a plausible trace: the
; silent-miscompile class (confirmed at HEAD 6ac1ae3: exit 0,
; `@ext(i32 %h)` + `cqrt_measure_i32(i32 %r)` in the output IR). The taint
; discipline only knows how to lower stock opcodes and cq intrinsics; an opaque
; callee is an unproven shape -> loud decline (Prime Directive). Visible-body
; in-module callees decline identically until Phase 6 clone-on-taint lands
; (sibling fixture lowering_reject_taint_escape_inmodule_body.ll).
;
; This was ALSO the hole that disarmed the Phase-5 net: an unknown CALL user
; makes the handle non-terminal (ChainWalk::isTerminalHandle returns false), so
; FreePoint's "unrecognized user" reject never even ran on it.
;
; Guard: TaintPropagation::declineTaintEscapes, wired FIRST in BOTH pipeline
; entry points (pre-RAUW SSA identity). Ownership split with the 659 angle
; guard: this guard owns the operand EDGE into the unknown callee; the rotation
; arg-1 ANGLE slot stays owned by RotationLowering::declineTaintedAngle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @ext(i32 %q)                      ; opaque consumer of the handle
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
