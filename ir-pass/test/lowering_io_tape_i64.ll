; lowering_io_tape_i64.ll — ACCEPT (Phase 7.6): `printf("%lld", x)` on a tainted
; i64 (C `long long`, suffix `sll`). The tape write picks `cqrt_tape_write_i64` by
; the operand's ABI width (read pre-RAUW); the handle is still i32 (Rule 15 — width
; lives only in the symbol name). Confirms the width family beyond the i32 default
; (realistic `%lld` args are i64 after varargs promotion). x is dead -> Bennett.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i64 @cq_theta_sll(i64, double)
declare i32 @printf(ptr, ...)
@.str = private constant [5 x i8] c"%lld\00"

define void @slice(i64 %u0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i64 %q)
  ret void
}

; The i64 arg is appended via the i64 width symbol; the source rail is reverse-
; played and freed after the tape write (Bennett):
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i64(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape
