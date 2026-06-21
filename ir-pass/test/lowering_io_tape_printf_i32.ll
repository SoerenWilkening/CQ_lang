; lowering_io_tape_printf_i32.ll — ACCEPT (Phase 7.6): a tainted `printf("%d", x)`
; lowers COHERENTLY to the reversible output tape. `x = cq_theta` -> printf, then
; x is dead. The tainted i32 arg is APPENDED (one lazy `cqrt_tape_alloc` + a
; `cqrt_tape_write_i32`) as a KEPT |0> output rail; x's own lineage then uncomputes
; normally (Bennett copy-out: the ry adjoint + `cqrt_free` land AFTER the tape write
; has captured the value). NO measurement is inserted (Rule 5), no `@printf` call
; survives, and the output rail is never freed/reversed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  ret void
}

; One lazy stdout tape; the tainted i32 arg appended to it; the SOURCE rail
; reverse-played (ry adjoint) and freed AFTER the tape write (Bennett); no
; measurement, no surviving printf call:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape
