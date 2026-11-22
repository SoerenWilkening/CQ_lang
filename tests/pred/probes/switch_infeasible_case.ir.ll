; USERCHECK f
; cq-us8cz (CR rules 8, 9): a quantum test's one arm holds a classical switch on %0; its 3200/3202 side switches on %0
; again, and that switch's case 0 edge into the join %6 is classically infeasible. Reduced by llvm-reduce from TinyEMU
; csr_read (its quantum argument made a cq_theta). The merge arm %spec.select of %6 is read on that edge's path, at a
; point with no join above: its care set (case 0) contradicts the point's facts (3200 or 3202), and the narrowing fell
; back to the care set alone, so the arm counted as needed (an internal error at pred's joinAbove).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i32 %0, i32 %1) {
  %q = call i32 @cq_theta_ui32(i32 %1, double 1.0)
  %b = trunc i32 %q to i1
  br i1 %b, label %8, label %3

3:
  switch i32 %0, label %6 [
    i32 1, label %8
    i32 2, label %8
    i32 3, label %8
    i32 0, label %4
    i32 3074, label %4
    i32 3200, label %5
    i32 3202, label %5
  ]

4:
  %spec.select = select i1 %b, i32 1, i32 0
  br label %6

5:
  switch i32 %0, label %8 [
    i32 0, label %6
  ]

6:
  %7 = phi i32 [ 0, %3 ], [ 0, %5 ], [ %spec.select, %4 ]
  br label %8

8:
  %r = phi i32 [ %7, %6 ], [ 9, %3 ], [ 9, %3 ], [ 9, %3 ], [ 8, %5 ], [ 5, %2 ]
  ret i32 %r
}
