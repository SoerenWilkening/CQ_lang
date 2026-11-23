; USERCHECK f
; cq-3630b (CR rules 8, 14): a K-loop (%h, quantum by %t8's test) holds a classical sub-loop %t11, reached only where the
; classical %a is false. Reduced by llvm-reduce from TinyCC decl (its quantum argument made a cq_theta; the trips given
; bounds, so that every input ends). The sub-loop's trip rail is the trip predicate and the quantum part of %t11's
; predicate, which reads %z, made in %t8 on the !%a paths only; it was read before the classical branch around the
; sub-loop, where the %a paths of the trip join (an internal error at pred's joinAbove). It is read only where the
; branch's classical condition holds.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i1 %a, i1 %b, i32 %nin) {
  %n = call i32 @cq_theta_ui32(i32 %nin, double 1.0)
  br label %h

h:
  %i = phi i8 [ 0, %0 ], [ %i1, %h ], [ %i1, %t8 ], [ %i1, %t11 ]
  %i1 = add i8 %i, 1
  %c = icmp ugt i8 %i1, 1
  br i1 %c, label %t7, label %h

t7:
  %done = icmp ugt i8 %i1, 5
  %stop = or i1 %a, %done
  br i1 %stop, label %ret, label %t8

t8:
  %z = icmp eq i32 %n, 0
  %and = and i1 %b, %z
  br i1 %and, label %h, label %t11

t11:
  %j = phi i8 [ 0, %t8 ], [ %j1, %t11 ]
  %j1 = add i8 %j, 1
  %out = icmp ugt i8 %j1, 2
  %back = or i1 %a, %out
  br i1 %back, label %h, label %t11

ret:
  %r = zext i8 %i1 to i32
  ret i32 %r
}
