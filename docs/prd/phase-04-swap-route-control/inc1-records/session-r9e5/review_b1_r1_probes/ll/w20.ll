target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; the ARM is a measured (classical) value
define i32 @main() {
  %q = call i32 @cq_theta_si32(i32 3, double 2.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = select i1 %b, i32 %mq, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %n = call i1 @cq_measure_i1(i1 %b)
  ret i32 %m
}
