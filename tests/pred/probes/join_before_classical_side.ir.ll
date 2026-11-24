; USERCHECK f
; cq-j3ffq (CR rules 8, 9): under a classical test (%c0) a quantum test's one arm (%B) holds a classical test whose
; true side joins the other arm at %J and whose false side %D comes after %J in the walk. The walk sends %B -> %D on
; to %J (an arm still to run); from %J it must still go to %D, though every arm of the quantum test reaches %J
; (cq-zueka's narrowing of cq-v11y saw no arm reaching %D alone). Shape of SoftFloat f16_mulAdd (cqsfi_fma_f16).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i32 %qin, i1 %c0, i1 %c) {
entry:
  %q = call i32 @cq_theta_ui32(i32 %qin, double 1.0)
  %t = icmp eq i32 %q, 0
  br i1 %c0, label %P, label %Q0

P:
  br label %J

Q0:
  br i1 %t, label %A, label %B

A:
  %a = add i32 %q, 1
  br label %J

B:
  br i1 %c, label %J, label %D

J:
  %j = phi i32 [ 0, %P ], [ %a, %A ], [ %q, %B ]
  br label %M

D:
  %d = mul i32 %q, 3
  br label %M

M:
  %m = phi i32 [ %j, %J ], [ %d, %D ]
  ret i32 %m
}
