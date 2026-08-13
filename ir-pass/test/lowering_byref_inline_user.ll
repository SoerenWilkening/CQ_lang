; lowering_byref_inline_user.ll — bd g7ip: by-ref out-param on a VISIBLE user
; function. `mysplit(v, &e)` writes `*out = v + 7` through a pointer out-param;
; clang -O1 (with the helper forced `noinline`) leaves it as
; `call void @mysplit(i32 %q, ptr %cell)` + a read-back `load`. ByRefInline PROVES
; the tight out-cell shape (g387 discipline) + the callee's pure single-store body,
; then INLINES the producer's value expression into the caller and RAUWs the load —
; byte-identical to the case where clang inlines the helper (Architecture A, owner
; decision 2026-07-01; see `bd memories g7ip-inline-producer-design`). The result
; lowers through the normal propagate/lowerOps path: theta -> alloc + ry, the
; inlined `add` -> cq_template_add_i32_hl, measure -> cqrt_measure. The now-dead
; internal callee is erased.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

define i32 @demo() {
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %cell)
  call void @mysplit(i32 %q, ptr %cell)
  %r = load i32, ptr %cell, align 4
  %m = call i32 @cq_measure_si32(i32 %r)
  call void @llvm.lifetime.end.p0(i64 4, ptr %cell)
  ret i32 %m
}

; The read-back load is replaced by the inlined `add nsw %q, 7`; the call, cell,
; loads, lifetimes, and the now-dead callee are gone.
; CHECK-NOT:   @mysplit
; CHECK-NOT:   alloca
; CHECK-NOT:   load
; CHECK-LABEL: define i32 @demo()
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:       %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[OP]])

define internal void @mysplit(i32 %v, ptr %out) {
  %r = add nsw i32 %v, 7
  store i32 %r, ptr %out, align 4
  ret void
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
