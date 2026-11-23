; USERCHECK f
; cq-3630b (CR rules 14, 16): a K-loop (%h) holds a sub-loop (%t, %in) with a quantum test %c, and all three of %h, %t
; and %latch leave into the noreturn arm %exit. Reduced by llvm-reduce from TinyCC rt_exit (its quantum arguments made
; cq_theta). Each trip evaluation lowers the arm's call under the arm's flag, which is exactly where that evaluation
; reaches the arm; the call's control conjoined the arm block's own predicate besides, which reads %c, minted in the
; sub-loop's trip and not on the latch's evaluation (an internal error at pred's joinAbove).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_theta_ui8(i8, double)
declare void @exit(i32) noreturn

define void @f(i32 %x, i8 %y, i32 %z) {
  %q = call i32 @cq_theta_ui32(i32 %x, double 1.0)
  %r = call i8 @cq_theta_ui8(i8 %y, double 1.0)
  %a = trunc i8 %r to i1
  br label %h

h:
  %or.cond = select i1 %a, i1 true, i1 false
  br i1 %or.cond, label %in, label %exit

t:
  %c = icmp ult i32 %q, %z
  br i1 %c, label %in, label %exit

in:
  br i1 %a, label %latch, label %t

latch:
  br i1 %a, label %exit, label %h

exit:
  call void @exit(i32 3)
  unreachable
}
