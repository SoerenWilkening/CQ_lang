; predmux_guarded_vla_accept_trip_ge_guard.ll —
; ACCEPT (bd xdu2.8). In a loop: `for (i<n) { if (q && m >= n) { b = p[i] > 4; … }
; measure b, c }`. The arm is the FALSE edge of `or (icmp slt m, n), (q == 0)`, so
; the fact is the negation `m >=s n`; with `n >= 0` (the loop guard) it is
; `extent >=u trips` through a zext chain (proof (T)): every index in [0, trips)
; is in bounds. Source: tests/e2e/railbank_guarded_vla_matrix.c CASE 5.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=LOAD < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty
;
; The speculated read is bounds-checked BY CONSTRUCTION: freeze both sides, compare,
; select the cell or the private zero constant, load through the select.
; CHECK: @cq.guarded.read.zero = private unnamed_addr constant i32 0
; CHECK: %cq.gr.idx = freeze i64
; CHECK-NEXT: %cq.gr.ext = freeze i64
; CHECK-NEXT: %cq.gr.inb = icmp ult i64 %cq.gr.idx, %cq.gr.ext
; CHECK-NEXT: %cq.gr.cell = getelementptr i32, ptr %{{[0-9]+}}, i64 %cq.gr.idx
; CHECK-NEXT: %cq.gr.addr = select i1 %cq.gr.inb, ptr %cq.gr.cell, ptr @cq.guarded.read.zero
; CHECK-NEXT: %[[V:[0-9]+]] = load i32, ptr %cq.gr.addr
; The loaded value stays CLASSICAL: it only ever reaches a compare whose i1 result
; occupies an `_hl` literal slot, and is never the operand of a `cqrt_alloc`.
; CHECK-NOT: cqrt_alloc_i32(i32 %[[V]])
; CHECK-NOT: cqrt_qram_
; CHECK: call i1 @cqrt_measure_i1
;
; Whole-file, its own prefix (Rule 12 (a)): exactly one i32 read in the module,
; and it is the guarded one — no unguarded read of the VLA survives anywhere.
; LOAD-NOT: load i32, ptr %{{[0-9]+}}
; LOAD: load i32, ptr %cq.gr.addr
; LOAD-NOT: load i32, ptr
;
; DBG-NOT: gate=E4

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  %4 = icmp slt i32 %1, 1
  %5 = or i1 %3, %4
  br i1 %5, label %49, label %6

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  %8 = tail call ptr @llvm.stacksave.p0()
  %9 = alloca i32, i64 %7, align 16
  %10 = zext nneg i32 %1 to i64
  br label %19

11:                                               ; preds = %19
  %12 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %26

14:                                               ; preds = %11
  %15 = icmp eq i32 %12, 0
  %16 = icmp slt i32 %1, %0
  %17 = or i1 %16, %15
  %18 = zext nneg i32 %0 to i64
  br label %30

19:                                               ; preds = %6, %19
  %20 = phi i64 [ 0, %6 ], [ %24, %19 ]
  %21 = getelementptr inbounds i32, ptr %9, i64 %20
  %22 = trunc i64 %20 to i32
  %23 = add i32 %22, 3
  store i32 %23, ptr %21, align 4, !tbaa !6
  %24 = add nuw nsw i64 %20, 1
  %25 = icmp eq i64 %24, %10
  br i1 %25, label %11, label %19, !llvm.loop !10

26:                                               ; preds = %38, %11
  %27 = phi i32 [ 0, %11 ], [ %46, %38 ]
  %28 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %29 = add nsw i32 %28, %27
  tail call void @llvm.stackrestore.p0(ptr %8)
  br label %49

30:                                               ; preds = %14, %38
  %31 = phi i64 [ 0, %14 ], [ %47, %38 ]
  %32 = phi i32 [ 0, %14 ], [ %46, %38 ]
  br i1 %17, label %38, label %33

33:                                               ; preds = %30
  %34 = getelementptr inbounds i32, ptr %9, i64 %31
  %35 = load i32, ptr %34, align 4, !tbaa !6
  %36 = icmp sgt i32 %35, 4
  %37 = icmp slt i32 %35, 9
  br label %38

38:                                               ; preds = %33, %30
  %39 = phi i1 [ %36, %33 ], [ false, %30 ]
  %40 = phi i1 [ %37, %33 ], [ false, %30 ]
  %41 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %39) #4
  %42 = zext i1 %41 to i32
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %40) #4
  %44 = zext i1 %43 to i32
  %45 = add nuw nsw i32 %32, %42
  %46 = add nuw nsw i32 %45, %44
  %47 = add nuw nsw i64 %31, 1
  %48 = icmp eq i64 %47, %18
  br i1 %48, label %26, label %30, !llvm.loop !13

49:                                               ; preds = %2, %26
  %50 = phi i32 [ %29, %26 ], [ 0, %2 ]
  ret i32 %50
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
