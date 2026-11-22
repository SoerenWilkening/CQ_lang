; USERCHECK f
; cq-us8cz (CR rules 8, 9): a quantum test's one arm holds a classical switch; its case 0/1 side runs a quantum switch
; into the join %10 that the 2944/2946 side reaches directly. Reduced by llvm-reduce from TinyEMU csr_read (its quantum
; argument made a cq_theta). The walk does not run %6 on the path of the cases 2944/2946, and the flag of %10's merge arm
; there reads %6's quantum switch value: those facts exclude the arm only by the exclusive cases of one switch, which
; the no-join don't-care test did not see (an internal error at pred's joinAbove).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i32 %0, i32 %1) {
  %3 = call i32 @cq_theta_ui32(i32 %0, double 1.0)
  %4 = trunc i32 %3 to i1
  br i1 %4, label %12, label %5

5:
  switch i32 %1, label %10 [
    i32 2946, label %9
    i32 2944, label %9
    i32 1, label %6
    i32 0, label %6
  ]

6:
  %7 = select i1 %4, i32 1, i32 0
  switch i32 %7, label %12 [
    i32 0, label %8
    i32 1, label %10
  ]

8:
  br label %10

9:
  br label %10

10:
  %11 = phi i32 [ 1, %5 ], [ 1, %6 ], [ 0, %9 ], [ 0, %8 ]
  br label %12

12:
  %13 = phi i32 [ 5, %2 ], [ %11, %10 ], [ 2, %6 ]
  ret i32 %13
}
