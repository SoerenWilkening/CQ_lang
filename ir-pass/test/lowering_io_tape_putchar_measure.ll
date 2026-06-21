; lowering_io_tape_putchar_measure.ll — ACCEPT (Phase 7.6): `putchar(x)` on a
; tainted x that is ALSO measured. The tape write is a SINK on x (it preserves x,
; ChainWalk::isOutputSink), so it does not block x; the user's `cq_measure` owns x
; — x is NOT reverse-played and NOT freed (the measure reclaims it). NO measurement
; is inserted by the tape lowering itself (Rule 5); the only measure is the one the
; user wrote. Confirms a tainted output sink composes with a downstream measure.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @putchar(i32)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @putchar(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The tainted arg is taped, then measured; the measure owns the rail, so there is
; NO cqrt_free of it (a measured register is reclaimed by the measurement):
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: cqrt_free
; CHECK-NOT: cq taint escape
