; lowering_reject_taint_escape_gep.ll — DECLINE: tainted value used as a
; `getelementptr` INDEX (quantum-indexed memory access) — the decline-by-default
; arm of the taint-escape guard (test_C_libtooling-bxv audit).
;
; A GEP is neither a lowerable opcode class (BinaryOperator/UnaryOperator/
; CmpInst/CastInst), nor control flow, nor a cq intrinsic: there is no
; reversible-template story for address arithmetic. After rotation lowering's
; RAUW the GEP indexes @arr by the RUNTIME HANDLE TAG and the load reads
; whatever lives there — untainted, classical, verify-clean.
;
; As in the store fixture, the handle is ALSO measured so the Phase-5
; FreePoint net (which returns Measured before its FirstUnrecognized check) is
; bypassed: HEAD 6ac1ae3 accepted this shape silently (exit 0,
; `getelementptr [8 x i32], ptr @arr, i32 0, i32 %h`). Any OTHER unsupported
; non-call user (atomicrmw, freeze, extractvalue, va_arg, ...) lands on this
; same generic decline arm — an unproven shape is declined, never guessed at
; (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@arr = global [8 x i32] zeroinitializer

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %g = getelementptr [8 x i32], ptr @arr, i32 0, i32 %q   ; quantum-indexed access
  %v = load i32, ptr %g
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
