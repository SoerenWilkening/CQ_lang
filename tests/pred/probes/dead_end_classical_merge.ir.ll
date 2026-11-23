; USERCHECK f
; cq-3630b (CR rules 9, 16): the dead end %4 is entered by the classical edge on %cond and by the quantum edge on %a out
; of %2. Reduced by llvm-reduce from TinyCC decl_initializer_alloc (its quantum argument made a cq_theta). The walk lowers
; %4 under its flag after %2 and goes on, also along the path that took the classical edge into %4, where C stops
; (`unreachable`) and %2's call never ran. The predicates give a dead end's share of a branch to its live sibling, so the
; merge %8 counted as needed on that path (an internal error at pred's joinAbove); it is a don't-care there.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)
declare i32 @abs(i32)

define i32 @f(i8 %qin, i1 %cond, i32 %v) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  %a = trunc i8 %q to i1
  br i1 %cond, label %4, label %2

2:
  %3 = call i32 @abs(i32 %v)
  br i1 %a, label %4, label %5

4:
  unreachable

5:
  br i1 %a, label %7, label %6

6:
  br label %7

7:
  %8 = phi i32 [ 0, %6 ], [ %3, %5 ]
  ret i32 %8
}
