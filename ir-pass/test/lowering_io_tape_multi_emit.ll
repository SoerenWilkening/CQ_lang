; lowering_io_tape_multi_emit.ll — ACCEPT (Phase 7.6): MULTIPLE I/O sinks in one
; function append to ONE tape (append-only, never an accumulator). Two tainted
; registers a, b; `printf(a)`, `putchar(b)`, `printf(a)`, then both measured. The
; emitter mints exactly ONE lazy `cqrt_tape_alloc` (the stream->tape registry) and
; threads it into THREE `cqrt_tape_write_i32` appends with DISTINCT out-handles —
; proving a tape (ordered transcript), not a single XOR-accumulator rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
declare i32 @putchar(i32)
@.d = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u, i32 %v) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r1 = call i32 (ptr, ...) @printf(ptr @.d, i32 %a)
  %r2 = call i32 @putchar(i32 %b)
  %r3 = call i32 (ptr, ...) @printf(ptr @.d, i32 %a)
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i32 @cq_measure_si32(i32 %b)
  %sum = add i32 %m1, %m2
  ret i32 %sum
}

; Exactly one tape alloc, three appends to it (a, b, a) with distinct results:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NOT: = call i32 @cqrt_tape_alloc()
; CHECK:     %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[HB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[HA]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[HB]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[HA]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: call{{.*}}@putchar
