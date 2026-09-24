; predmux_guarded_vla_accept_user_zero_global_aligned.ll — ACCEPT (bd xdu2.8, Rule-13 round 2 P3).
; predmux_guarded_vla_accept_user_zero_global.ll with the USER global's alignment raised
; BY HAND to 16, so size, type, address space and alignment all qualify it for reuse and
; ONLY the pass's own `!cq.guarded.read.zero` marker tells it apart. It must not be
; reused (a user object is not the pass's to alias). Kills mutant M29, which the align-1
; sibling fixture cannot see.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; CHECK: @cq.guarded.read.zero = private unnamed_addr constant i32 0, align 16{{$}}
; CHECK: @[[Z:cq.guarded.read.zero.[0-9]+]] = private unnamed_addr constant i32 0, align 4{{$}}
; CHECK: %cq.gr.addr = select i1 %cq.gr.inb, ptr %cq.gr.cell, ptr @[[Z]]

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %0)
  %5 = add i32 %0, 5
  %6 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %5)
  %7 = add nsw i32 %6, %4
  ret i32 %7
}

; Function Attrs: noinline nounwind ssp uwtable
@cq.guarded.read.zero = private unnamed_addr constant i32 0, align 16
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %37, label %4

4:                                                ; preds = %2
  %5 = zext nneg i32 %0 to i64
  %6 = tail call ptr @llvm.stacksave.p0()
  %7 = alloca i32, i64 %5, align 16
  %8 = zext nneg i32 %0 to i64
  br label %14

9:                                                ; preds = %14
  %10 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %11 = icmp ne i32 %10, 0
  %12 = icmp ult i32 %1, %0
  %13 = and i1 %12, %11
  br i1 %13, label %21, label %27

14:                                               ; preds = %4, %14
  %15 = phi i64 [ 0, %4 ], [ %19, %14 ]
  %16 = getelementptr inbounds i32, ptr %7, i64 %15
  %17 = trunc i64 %15 to i32
  %18 = add i32 %17, 3
  store i32 %18, ptr %16, align 4, !tbaa !6
  %19 = add nuw nsw i64 %15, 1
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %9, label %14, !llvm.loop !10

21:                                               ; preds = %9
  %22 = zext nneg i32 %1 to i64
  %23 = getelementptr inbounds i32, ptr %7, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !6
  %25 = icmp sgt i32 %24, 4
  %26 = icmp slt i32 %24, 9
  br label %27

27:                                               ; preds = %21, %9
  %28 = phi i1 [ %25, %21 ], [ false, %9 ]
  %29 = phi i1 [ %26, %21 ], [ false, %9 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %32 = zext i1 %31 to i32
  %33 = add nsw i32 %30, %32
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #4
  %35 = zext i1 %34 to i32
  %36 = add nsw i32 %33, %35
  tail call void @llvm.stackrestore.p0(ptr %6)
  br label %37

37:                                               ; preds = %2, %27
  %38 = phi i32 [ %36, %27 ], [ 0, %2 ]
  ret i32 %38
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

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
