; USERCHECK f
; cq-us8cz (CR rules 8, 9): a quantum test's one arm holds a classical switch on %0. Its 0/3074 side runs a quantum
; switch and its 3200/3202 side a classical one, and both lead into the join %13. Reduced by llvm-reduce from TinyEMU
; csr_read (its quantum operand made a cq_theta). On the 3200/3202 path the flag of %13 is read at a point with no join
; above. There the predicate is the classical switch's own condition: the quantum switch's part (cases 0/3074) drops
; out only because the cases of the switch on %0 exclude each other, which the BDD restriction does not see. That part
; read %spec.select where the walk did not run its block (an internal error at pred's joinAbove).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i32 %0, i32 %qin) {
  %t = call i32 @cq_theta_ui32(i32 %qin, double 1.0)
  %2 = trunc i32 %t to i8
  %3 = zext i8 %2 to i32
  %4 = icmp ugt i32 0, %3
  br i1 %4, label %15, label %5

5:
  switch i32 %0, label %13 [
    i32 1, label %15
    i32 2, label %15
    i32 3, label %15
    i32 0, label %6
    i32 3074, label %6
    i32 3200, label %10
    i32 3202, label %10
  ]

6:
  %7 = icmp ult i8 %2, 0
  %spec.select = select i1 %7, i32 1, i32 0
  switch i32 %spec.select, label %15 [
    i32 0, label %8
    i32 1, label %13
  ]

8:
  br label %13

10:
  %11 = phi i32 [ 0, %5 ], [ 0, %5 ]
  switch i32 %11, label %15 [
    i32 0, label %12
    i32 1, label %13
  ]

12:
  br label %13

13:
  %14 = phi i32 [ 1, %10 ], [ 1, %6 ], [ 0, %12 ], [ 0, %8 ], [ 0, %5 ]
  br label %15

15:
  ret i32 0
}
