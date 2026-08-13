; lowering_io_tape_measure_then_tape.ll — ACCEPT (Phase 7.6, Rule-13 R1): writing
; a value to the output tape AFTER it was measured is legitimate (the tape records
; the now-classical measured value). A `cqrt_tape_write` reads-and-PRESERVES its
; src — it is NOT a gate applied after measurement, so FreePoint exempts it from
; the post-measure-use reject (it would otherwise false-fire `kMsgPostMeasure`
; because a tape write matches the `cqrt_` ordinary-use prefix). The measure owns
; the rail, so it is not freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %r = call i32 (ptr, ...) @printf(ptr @.d, i32 %q)
  ret i32 %m
}

; Measure first (owns the rail), then the tape write of the same handle; no free,
; no post-measure reject, no surviving printf call:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_free
