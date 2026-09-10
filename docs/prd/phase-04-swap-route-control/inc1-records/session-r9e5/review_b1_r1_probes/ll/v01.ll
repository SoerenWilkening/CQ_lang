target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; VALUE ARM under a COMPOUND rail condition (xor tree) — can it reach
; emitValueRegion -> emitSelectRegion without the rail ladder?
define i32 @main() {
entry:
  %a = call i32 @cq_theta_si32(i32 5, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 false, double 7.000000e-01)
  %t = xor i1 %b, %c
  br i1 %t, label %arm, label %join
arm:
  %a2 = add i32 %a, 3
  br label %join
join:
  %m = phi i32 [ %a, %entry ], [ %a2, %arm ]
  %r = call i32 @cq_measure_si32(i32 %m)
  %n = call i1 @cq_measure_i1(i1 %b)
  %o = call i1 @cq_measure_i1(i1 %c)
  ret i32 %r
}
