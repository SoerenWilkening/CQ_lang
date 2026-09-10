target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

; the theta on the rail is AFTER the select but in a block the select does not
; dominate is impossible; instead: theta after select, select inside a loop body
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc1, %loop ]
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %acc1 = add i32 %acc, %m
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %out
out:
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %o = call i1 @cq_measure_i1(i1 %b2)
  ret i32 %acc1
}
