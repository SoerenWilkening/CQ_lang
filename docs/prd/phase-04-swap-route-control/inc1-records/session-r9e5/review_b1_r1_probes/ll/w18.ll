target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; the select result feeds a SECOND select's CONDITION via a compare (round-2 shape)
define i32 @main() {
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %s = select i1 %b, i32 2, i32 5
  %c = icmp sgt i32 %s, 3
  %t = select i1 %c, i32 7, i32 9
  %m = call i32 @cq_measure_si32(i32 %t)
  %n = call i1 @cq_measure_i1(i1 %b)
  ret i32 %m
}
