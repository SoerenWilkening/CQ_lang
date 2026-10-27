; Declares CQ.h functions (and a CQ_K constant) but never calls them: no taint source.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@__cq_k_f = constant i32 7, align 4
@llvm.used = appending global [1 x ptr] [ptr @__cq_k_f], section "llvm.metadata"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @f(i32 %x) {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}
