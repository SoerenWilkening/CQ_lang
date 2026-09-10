target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)
declare void @cq_phi(double)

; the second select's TRUE arm is the first select's %out, same rail condition
define i32 @main() {
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %s1 = select i1 %b, i32 2, i32 5
  %s2 = select i1 %b, i32 %s1, i32 9
  %m  = call i32 @cq_measure_si32(i32 %s2)
  %n  = call i1 @cq_measure_i1(i1 %b)
  ret i32 %m
}
