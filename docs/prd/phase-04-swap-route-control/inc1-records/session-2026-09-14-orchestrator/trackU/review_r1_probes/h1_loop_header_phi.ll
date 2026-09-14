; F-U1 attack: does the phi half rewrite a LOOP HEADER phi's preheader incoming?
; Track L's L-3 says `bool b = 0` gives railPhiRootMint NO MINT, so a
; preheader undef -> i1 false is a classification-visible change.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_i32(i32)

define i1 @example(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %b = phi i1 [ undef, %entry ], [ %t, %loop ]
  %t = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %out
out:
  %m = call i1 @cq_measure_i1(i1 %b)
  ret i1 %m
}
