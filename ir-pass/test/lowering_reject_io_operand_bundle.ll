; lowering_reject_io_operand_bundle.ll — DECLINE (Phase 7.6, Rule-13 R3): a
; `printf` whose ONLY tainted operand is an OPERAND-BUNDLE operand (not a
; positional argument). `readsTaintedValue` (the escape guard) scans all operands
; incl. bundles, but `lowerIOSinks` only tapes positional `CI->args()` — so an
; unguarded carve would suppress the escape decline while the emitter lowers
; nothing, leaving the `printf` to read the i32 runtime handle after rotation
; lowering (a verify-clean opaque-call silent miscompile). The carve and
; `isRecognizedIOSink` therefore BOTH reject a sink carrying operand bundles, so
; the tainted bundle operand falls through to the loud unknown-callee decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.d) [ "deopt"(i32 %q) ]
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
