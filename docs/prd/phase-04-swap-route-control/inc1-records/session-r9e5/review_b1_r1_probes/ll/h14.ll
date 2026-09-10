target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)
declare void @cq_phi(double)

; measure of the PARENT NAME before the select (r02 in hand IR, no chained rotation between)
define i32 @main() {
  %b0 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 %b0, double 3.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b0)
  %s  = select i1 %b, i32 2, i32 5
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
