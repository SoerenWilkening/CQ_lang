; lowering_io_passthrough_classical.ll — PASSTHROUGH (Phase 7.6): a `printf` whose
; arguments are all CLASSICAL (no tainted value) is NOT a recognized I/O sink for
; the tape lowering — it is left byte-untouched, exactly as before 7.6. The carve
; in `declineTaintEscapes` and the `lowerIOSinks` emitter both gate on a tainted
; argument; a classical `printf` never reaches either. The unrelated tainted q is
; still measured normally. Guards against the emitter over-reaching to every printf.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.d, i32 %c)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The classical printf survives verbatim; no tape is emitted; the tainted q lowers
; to a measure as usual:
; CHECK:     call i32 (ptr, ...) @printf(ptr @.d, i32 %c)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: cqrt_tape
; CHECK-NOT: cq taint escape
