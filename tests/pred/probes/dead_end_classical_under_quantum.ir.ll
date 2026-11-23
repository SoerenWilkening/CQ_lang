; USERCHECK f
; cq-3630b (CR rules 9, 16): the classical branch on %cond into the dead end %4 sits under the quantum predicate %b; %4 is
; also entered by the quantum edge on %a out of %2. Reduced by hand from TinyCC decl_initializer_alloc (a classical switch
; on an argument into a noreturn arm, under a quantum predicate, before a merge of a value minted after it). On %b & %cond
; C stops, but the walk goes on along that path, and the merge %8 counted as needed there, where %3 was never minted (an
; internal error at pred's joinAbove); it is a don't-care there.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)
declare i32 @abs(i32)

define i32 @f(i8 %qin, i1 %cond, i32 %v) {
  %q = call i8 @cq_theta_ui8(i8 %qin, double 1.0)
  %a = trunc i8 %q to i1
  %s = lshr i8 %q, 1
  %b = trunc i8 %s to i1
  br i1 %b, label %1, label %7

1:
  br i1 %cond, label %4, label %2

2:
  %3 = call i32 @abs(i32 %v)
  br i1 %a, label %4, label %5

4:
  unreachable

5:
  br label %7

7:
  %8 = phi i32 [ 0, %0 ], [ %3, %5 ]
  ret i32 %8
}
