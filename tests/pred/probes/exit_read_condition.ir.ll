; USERCHECK f
; USERCHECK g
; cq-dhwdv (CR rule 3 "Loops", rules 8, 14): a classical compare made in a quantum-exit loop and branched on after it.
; Reduced by llvm-reduce from TinyCC main (a pointer compare there; the quantum test a shifted register here, so that
; every input ends). In @f the compare %u is the loop's classical exit test besides (case 3: a classical bound with a
; quantum exit); in @g it is a loop invariant. After the loop it depends on which trip exited and the loop captured it
; into a rail, but the branch's atom read it as classical (an internal error at pred's atomValue, "a classical atom
; whose operand is a rail", or the spine's "a classical branch on a rail"). Taint makes %u itself quantum.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)

define i32 @f(i8 %n, i8 %qin) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  br label %h

h:
  %i = phi i8 [ %n, %0 ], [ %i1, %t ]
  %qs = phi i8 [ %q, %0 ], [ %qs1, %t ]
  %u = icmp ugt i8 %i, 2
  br i1 %u, label %t, label %out

t:
  %i1 = sub i8 %i, 1
  %b = and i8 %qs, 1
  %cond = icmp eq i8 %b, 0
  %sh = lshr i8 %qs, 1
  %qs1 = or i8 %sh, -128
  br i1 %cond, label %h, label %out

out:
  br i1 %u, label %d1, label %d2

d1:
  ret i32 1

d2:
  ret i32 2
}

define i32 @g(i8 %n, i8 %qin) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  br label %in

in:
  %qs = phi i8 [ %q, %0 ], [ %qs1, %in ]
  %u = icmp ugt i8 %n, 3
  %b = and i8 %qs, 1
  %cond = icmp eq i8 %b, 0
  %sh = lshr i8 %qs, 1
  %qs1 = or i8 %sh, -128
  br i1 %cond, label %in, label %out

out:
  br i1 %u, label %d1, label %d2

d1:
  ret i32 1

d2:
  ret i32 2
}
