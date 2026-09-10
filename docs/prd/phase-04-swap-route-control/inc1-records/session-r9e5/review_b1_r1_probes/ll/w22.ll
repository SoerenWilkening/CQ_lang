target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; TWO rail-conditioned selects in ONE block on TWO rails, interleaved so region 1
; and region 2 streams could slide into each other
define i32 @main() {
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = call i1 @cq_theta_i1(i1 false, double 7.000000e-01)
  %s1 = select i1 %b, i32 2, i32 5
  %s2 = select i1 %c, i32 7, i32 9
  %a  = add i32 %s1, %s2
  %m  = call i32 @cq_measure_si32(i32 %a)
  %n  = call i1 @cq_measure_i1(i1 %b)
  %o  = call i1 @cq_measure_i1(i1 %c)
  ret i32 %m
}
