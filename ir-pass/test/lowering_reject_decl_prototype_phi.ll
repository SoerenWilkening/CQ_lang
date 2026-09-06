; lowering_reject_decl_prototype_phi.ll — DECLINE: user-declared @cq_phi with the
; WRONG prototype.
;
; REWRITTEN 2026-09-05 FOR THE REGISTER-FREE SURFACE (bd test_C_libtooling-3qlq
; Inc 1, PRD `retire-swap-route-PRD.md` §4.1). The decision, recorded here rather
; than left to be re-derived:
;
;   * WHAT IT USED TO PIN: `declare i32 @cq_phi_si32(i32, float)` — a malformed
;     member of the 15-width family — rendering `… for cq_phi_si32`.
;   * WHY THAT ASSERTION IS GONE: the family is RETIRED. `CQ.h` no longer declares
;     it and `resolveSources` no longer RESOLVES it, so there is nothing left to
;     prototype-validate under that name and a wrong-typed `@cq_phi_si32` is now
;     just an unknown external. Its disposition is pinned by
;     `lowering_reject_legacy_phi_register_form.ll` instead (a tainted operand
;     into an opaque callee → `cq taint escape`).
;   * WHAT IT PINS NOW: the SAME guard on the SAME reserved name, one surface
;     later. `@cq_phi` is resolved by EXACT name and must have the prototype
;     `void(double)`; anything else declines LOUDLY at collection time.
;
; THE GUARD IS NOT COSMETIC AT THIS SURFACE — it is what makes every downstream
; `getArgOperand(0)` read of a phase call an ANGLE read. `cq_phi`'s single operand
; IS the angle, so a declaration with a different arity or type would drive the
; kickback emitter into passing something that is not a `double` to
; `cqrt_rz_i1(i32, double)`. That is loud only at the FINAL verifier (Broken
; module, opt exit 134), not in the pass's source-located
; DiagnosticInfoUnsupported dialect — which is exactly the gap
; test_C_libtooling-pn2 opened this guard for.
;
; THE RESERVED-NAME RULE IS UNCHANGED AND IS WHY THE CALL SITE HERE IS OPTIONAL:
; the 42-name surface (now 43, with `cq_phi`) is reserved BY CONVENTION, so a
; wrong-typed declaration declines whether or not it is currently called
; (`lowering_reject_decl_prototype_unused.ll` pins that boundary choice). The
; theta and measure declarations here are CORRECT and are accepted by the same
; validator; only the malformed `@cq_phi` declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi(double)                    ; WRONG: must be void(double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %p = call i32 @cq_phi(double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported declared prototype for cq_phi
