; USERCHECK f
; cq-zueka (CR rules 8, 9): a quantum test's one arm holds a classical test (%13) whose two sides meet later: %14's
; classical edge into %17 and %15 (the other side) both lead on. Reduced by llvm-reduce from TinyEMU fma_sf32 (its
; quantum argument made a cq_theta). Walker::next took %15 as an arm still to run on the edge %14 -> %17 (cq-v11y:
; the quantum branch at the entry reaches both) though that branch has one arm holding both; %15's guard then sent the
; paths of %14 -> %17 past %17, and the return's merge arm %spec.select was read where it was not minted: an internal
; error at pred's joinAbove.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_ui32(i32, double)

define i32 @f(i32 %0, i32 %qin, i1 %2, i1 %3, i1 %4) {
  %q = call i32 @cq_theta_ui32(i32 %qin, double 1.0)
  %6 = and i32 %0, 255
  %7 = lshr i32 %q, 23
  %8 = and i32 %7, 255
  %9 = icmp eq i32 %8, 255
  br i1 %9, label %11, label %12

11:
  ret i32 0

12:
  %13 = icmp eq i32 %6, 0
  br i1 %13, label %14, label %15

14:
  br i1 %4, label %17, label %16

15:
  br label %16

16:
  br i1 %3, label %17, label %18

17:
  %spec.select = select i1 %2, i32 0, i32 %q
  ret i32 %spec.select

18:
  ret i32 0
}
