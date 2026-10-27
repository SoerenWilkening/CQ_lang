; cq-bym: every CQ.h surface function is referenced, none is called directly. Owner ruling 2 on
; cq-arch: the early exit tests calls, so this module passes through byte-identical. The references
; are an @llvm.used entry, a global initializer, a constant expression, a store of the address, and
; the function passed as a call argument (a CallBase user that is not the callee). Nothing calls
; through any of these addresses.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@p_measure = global ptr @cq_measure_si32, align 8
@p_end = global i64 ptrtoint (ptr @__cq_invert_end to i64), align 8
@sink = global ptr null, align 8
@llvm.used = appending global [1 x ptr] [ptr @cq_phi], section "llvm.metadata"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
declare void @__cq_invert_begin()
declare void @__cq_invert_end()
declare void @take(ptr)

define void @f() {
entry:
  store ptr @__cq_invert_begin, ptr @sink, align 8
  call void @take(ptr @cq_theta_si32)
  ret void
}
