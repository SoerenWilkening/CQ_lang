target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)
declare void @cq_phi(double)

; mixed tree; the theta lands on the COMPARE's register after the select
define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 3, double 2.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %cm = icmp sgt i32 %q, 5
  %t  = and i1 %b, %cm
  %s  = select i1 %t, i32 2, i32 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %m  = call i32 @cq_measure_si32(i32 %s)
  %n  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
