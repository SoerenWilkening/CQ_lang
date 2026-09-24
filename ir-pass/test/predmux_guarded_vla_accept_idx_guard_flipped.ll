; predmux_guarded_vla_accept_idx_guard_flipped.ll —
; ACCEPT (bd xdu2.8). CASE 1 spelled `m > k && q`: the guard is the CONDITION of
; a logical-and `select i1 %gt, i1 %q, i1 false` (not an `and i1`), and its
; predicate is `ugt` with the extent on the LEFT, so the fact is canonicalised by
; swapping. Source: tests/e2e/railbank_guarded_vla_matrix.c CASE 2.
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
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = sext i32 %0 to i64
  %5 = getelementptr ptr, ptr %1, i64 %4
  %6 = getelementptr i8, ptr %5, i64 -8
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = add i32 %8, %0
  %10 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %9)
  ret i32 %10
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %40, label %4

4:                                                ; preds = %2
  %5 = zext nneg i32 %0 to i64
  %6 = tail call ptr @llvm.stacksave.p0()
  %7 = alloca i32, i64 %5, align 16
  %8 = zext nneg i32 %0 to i64
  br label %15

9:                                                ; preds = %15
  %10 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #5
  %11 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #5
  %12 = icmp ugt i32 %0, %1
  %13 = icmp ne i32 %10, 0
  %14 = select i1 %12, i1 %13, i1 false
  br i1 %14, label %22, label %28

15:                                               ; preds = %4, %15
  %16 = phi i64 [ 0, %4 ], [ %20, %15 ]
  %17 = getelementptr inbounds i32, ptr %7, i64 %16
  %18 = trunc i64 %16 to i32
  %19 = add i32 %18, 3
  store i32 %19, ptr %17, align 4, !tbaa !10
  %20 = add nuw nsw i64 %16, 1
  %21 = icmp eq i64 %20, %8
  br i1 %21, label %9, label %15, !llvm.loop !12

22:                                               ; preds = %9
  %23 = zext nneg i32 %1 to i64
  %24 = getelementptr inbounds i32, ptr %7, i64 %23
  %25 = load i32, ptr %24, align 4, !tbaa !10
  %26 = icmp sgt i32 %25, 4
  %27 = icmp slt i32 %25, 9
  br label %28

28:                                               ; preds = %22, %9
  %29 = phi i1 [ %26, %22 ], [ false, %9 ]
  %30 = phi i1 [ %27, %22 ], [ false, %9 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %32 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  %33 = add nsw i32 %32, %31
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #5
  %35 = zext i1 %34 to i32
  %36 = add nsw i32 %33, %35
  %37 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30) #5
  %38 = zext i1 %37 to i32
  %39 = add nsw i32 %36, %38
  tail call void @llvm.stackrestore.p0(ptr %6)
  br label %40

40:                                               ; preds = %2, %28
  %41 = phi i32 [ %39, %28 ], [ 0, %2 ]
  ret i32 %41
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
