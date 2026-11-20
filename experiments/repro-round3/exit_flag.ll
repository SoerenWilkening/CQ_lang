; cq-03rdt (SQLite sqlite3_get_table_cb, after llvm-reduce): a loop with two entries (a classical branch, and the
; continue edge of a quantum branch whose other edge goes to the error block) with a quantum exit (a bus load is 0) to the
; error block and an invariant classical exit. The loop is a K-loop; the flag of the classical exit's block (its store)
; is built per edge at the loop's exit join, and the edge from the latch was built at the latch's end: minted on every
; trip after the loop's records were closed, and nothing freed it ("still pending at a return its definition does not
; dominate"). Hand-written IR: clang -O1 merged or unswitched the two exits of every C form tried.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@tab = global [4 x i64] [i64 0, i64 3, i64 0, i64 5], align 16
@st = global i32 0, align 4

declare i64 @cq_theta_sl(i64 noundef, double noundef)

define i32 @exit_flag(i64 noundef %0, i64 noundef %1) {
  %3 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 5.000000e-01)
  store i64 %3, ptr @tab, align 16
  %4 = and i64 %1, 2
  %5 = icmp eq i64 %4, 0
  br i1 %5, label %6, label %8

6:
  %7 = icmp eq i64 %3, 7
  br i1 %7, label %19, label %8

8:
  %9 = phi i64 [ 0, %2 ], [ 0, %6 ], [ %15, %14 ]
  %10 = and i64 %9, 3
  %11 = getelementptr inbounds [4 x i64], ptr @tab, i64 0, i64 %10
  %12 = load i64, ptr %11, align 8
  %13 = icmp eq i64 %12, 0
  br i1 %13, label %19, label %14

14:
  %15 = add nuw nsw i64 %9, 1
  %16 = and i64 %1, 1
  %17 = icmp ne i64 %16, 0
  br i1 %17, label %18, label %8

18:
  store i32 1, ptr @st, align 4
  ret i32 0

19:
  ret i32 1
}
