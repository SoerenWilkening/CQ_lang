; lowering_io_tape_i64.ll — ACCEPT (Phase 7.6): `printf("%lld", x)` on a tainted
; i64 (C `long long`, suffix `sll`). The tape write picks `cqrt_tape_write_i64` by
; the operand's ABI width (read pre-RAUW); the handle is still i32 (Rule 15 — width
; lives only in the symbol name). Confirms the width family beyond the i32 default
; (realistic `%lld` args are i64 after varargs promotion).
;
; x is dead, and it IS reverse-played — but never freed: it is RECORDED on the kept
; tape and therefore LEFT ALLOCATED (bd 261j(a), owner ruling 2026-08-10). The
; record freeze is width-blind, exactly like the tape ABI it keys on. See
; lowering_io_tape_printf_i32.ll for the full algebra and for why the adjoint stays;
; the point HERE is only that the freeze does not accidentally key on i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
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
; played at that width and then LEFT ALLOCATED (recorded on a kept carrier):
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i64(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_ry_i64(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: cqrt_free
