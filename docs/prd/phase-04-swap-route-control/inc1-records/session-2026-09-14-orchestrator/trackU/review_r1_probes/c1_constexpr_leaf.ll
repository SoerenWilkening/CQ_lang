; the ConstantExpr residual: valueCarriesUndef is TRUE, isa<UndefValue> is FALSE.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@g = global [4 x i32] zeroinitializer

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 ptrtoint (ptr getelementptr ([4 x i32], ptr @g, i64 0, i64 undef) to i32), double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
