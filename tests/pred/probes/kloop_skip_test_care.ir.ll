; USERCHECK f
; cq-3630b (CR rules 8, 14): a K-loop whose going-on predicate is a classical conjunct (%k != 0) and a quantum rest that
; reads the classical atom %n0, made in a block (%7) only the %k != 0 paths of a trip reach. Reduced by llvm-reduce from
; TinyCC decl (its quantum arguments made a cq_theta; the trips given a bound, the quantum tests a shifted register, so
; that every input ends). The trip's test reads the rest's flag before it branches on the conjunct, at a point where the
; %k == 0 paths of the trip join, on which %n0 was never made: the flag had no don't-care there (an internal error at
; pred's joinAbove). It is read only where the conjunct holds.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)

define i32 @f(i8 %qin, i32 %k, i32 %n, i32 %m) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  %c4 = icmp eq i32 %k, 0
  br label %h

h:
  %c = phi i8 [ 0, %0 ], [ %c1, %t7 ], [ %c1, %t11 ], [ %c1, %t14 ]
  %qs = phi i8 [ %q, %0 ], [ %qs1, %t7 ], [ %qs1, %t11 ], [ %qs1, %t14 ]
  %c1 = add i8 %c, 1
  %sh = lshr i8 %qs, 1
  %qs1 = or i8 %sh, -128
  %a = trunc i8 %qs to i1
  %s1 = lshr i8 %qs, 1
  %b = trunc i8 %s1 to i1
  %done = icmp ugt i8 %c1, 5
  br i1 %done, label %out, label %body

body:
  br i1 %a, label %t6, label %t14

t6:
  br i1 %c4, label %out, label %t7

t7:
  %qw = zext i8 %qs to i32
  %v = add i32 %qw, %m
  %n0 = icmp eq i32 %n, 0
  %and = and i1 %b, %n0
  br i1 %and, label %h, label %t11

t11:
  %z = icmp eq i32 %v, 0
  br i1 %z, label %h, label %ret0

ret0:
  ret i32 0

t14:
  br i1 %c4, label %out, label %h

out:
  ret i32 1
}
